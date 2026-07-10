import 'dart:ui';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sugerencia de ciudad devuelta por Google Places Autocomplete.
class CityPrediction {
  const CityPrediction({
    required this.placeId,
    required this.name,
    required this.description,
  });

  /// Identificador estable de Google (cities.google_place_id).
  final String placeId;

  /// Nombre de la localidad, p. ej. "A Coruña".
  final String name;

  /// Texto completo para desambiguar homónimos, p. ej. "Toro, Zamora, España".
  final String description;
}

/// Sugerencia de dirección o barrio devuelta por Places Autocomplete.
class AddressPrediction {
  const AddressPrediction({
    required this.placeId,
    required this.name,
    required this.description,
  });

  final String placeId;

  /// Texto principal, p. ej. "Rúa Real, 12" u "Os Castros".
  final String name;

  /// Texto completo, p. ej. "Rúa Real, 12, A Coruña, España".
  final String description;
}

/// Detalles estructurados de un lugar (Place Details con field mask mínima).
class PlaceDetails {
  const PlaceDetails({
    required this.placeId,
    this.formattedAddress,
    this.neighborhood,
    this.latitude,
    this.longitude,
    required this.isPreciseAddress,
  });

  final String placeId;
  final String? formattedAddress;

  /// Barrio derivado de los address components (neighborhood/sublocality).
  final String? neighborhood;
  final double? latitude;
  final double? longitude;

  /// true si el lugar es una dirección con calle (no un barrio o zona).
  final bool isPreciseAddress;
}

/// Acceso a Google Places (API nueva). Abstracto para poder falsearlo en tests.
abstract class PlacesService {
  /// Sugerencias de localidades de España para [query].
  Future<List<CityPrediction>> autocompleteCities(String query);

  /// Sugerencias de direcciones/zonas de España. Con [cityName] la búsqueda
  /// se sesga a esa ciudad; con [neighborhoodsOnly] solo devuelve barrios.
  Future<List<AddressPrediction>> autocompleteAddresses(
    String query, {
    String? cityName,
    bool neighborhoodsOnly = false,
  });

  /// Detalles estructurados de un lugar. Consume la sesión de autocompletado
  /// en curso (Places factura autocomplete + details como una sola sesión).
  Future<PlaceDetails> fetchDetails(String placeId);

  /// Cierra la sesión de autocompletado actual. Llamar tras cada selección:
  /// la siguiente búsqueda abrirá un session token nuevo (Places factura por
  /// sesión, no por pulsación).
  void endSession();
}

class GooglePlacesService implements PlacesService {
  FlutterGooglePlacesSdk? _sdk;
  bool _startNewSession = true;

  FlutterGooglePlacesSdk get _client {
    return _sdk ??= FlutterGooglePlacesSdk(
      _requireApiKey(),
      locale: const Locale('es', 'ES'),
      useNewApi: true,
    );
  }

  static String _requireApiKey() {
    final key = dotenv.env['GOOGLE_PLACES_API_KEY'];
    if (key == null || key.isEmpty) {
      throw StateError('Falta GOOGLE_PLACES_API_KEY en el fichero .env');
    }
    return key;
  }

  @override
  Future<List<CityPrediction>> autocompleteCities(String query) async {
    final response = await _client.findAutocompletePredictions(
      query,
      countries: const ['es'],
      placeTypesFilter: const [PlaceTypeFilter.CITIES],
      newSessionToken: _startNewSession ? true : null,
    );
    _startNewSession = false;
    return response.predictions
        .map(
          (prediction) => CityPrediction(
            placeId: prediction.placeId,
            name: prediction.primaryText,
            description: prediction.fullText,
          ),
        )
        .toList();
  }

  /// Tipos de Places que identifican un barrio/zona (no una calle).
  static const _neighborhoodPlaceTypes = {
    PlaceType.NEIGHBORHOOD,
    PlaceType.SUBLOCALITY,
    PlaceType.SUBLOCALITY_LEVEL_1,
  };

  /// Tipos de Places que identifican una dirección con calle.
  static const _streetPlaceTypes = {
    PlaceType.STREET_ADDRESS,
    PlaceType.ROUTE,
    PlaceType.PREMISE,
    PlaceType.SUBPREMISE,
  };

  @override
  Future<List<AddressPrediction>> autocompleteAddresses(
    String query, {
    String? cityName,
    bool neighborhoodsOnly = false,
  }) async {
    // El SDK solo permite sesgar por coordenadas; añadir la ciudad a la
    // consulta consigue el mismo efecto sin conocer su geometría.
    final biasedQuery = cityName == null ? query : '$query, $cityName';
    final response = await _client.findAutocompletePredictions(
      biasedQuery,
      countries: const ['es'],
      placeTypesFilter: [
        neighborhoodsOnly ? PlaceTypeFilter.REGIONS : PlaceTypeFilter.GEOCODE,
      ],
      newSessionToken: _startNewSession ? true : null,
    );
    _startNewSession = false;
    Iterable<AutocompletePrediction> predictions = response.predictions;
    if (neighborhoodsOnly) {
      // REGIONS también devuelve localidades y códigos postales; se filtra a
      // barrios (si Places no informa tipos, se deja pasar la sugerencia).
      predictions = predictions.where((prediction) {
        final types = prediction.placeTypes;
        if (types == null || types.isEmpty) return true;
        return types.any(_neighborhoodPlaceTypes.contains);
      });
    }
    return predictions
        .map(
          (prediction) => AddressPrediction(
            placeId: prediction.placeId,
            name: prediction.primaryText,
            description: prediction.fullText,
          ),
        )
        .toList();
  }

  @override
  Future<PlaceDetails> fetchDetails(String placeId) async {
    try {
      final response = await _client.fetchPlace(
        placeId,
        fields: const [
          PlaceField.Address,
          PlaceField.AddressComponents,
          PlaceField.Location,
          PlaceField.Types,
        ],
      );
      final place = response.place;
      if (place == null) {
        throw StateError('Places no devolvió detalles para $placeId');
      }
      return PlaceDetails(
        placeId: placeId,
        formattedAddress: place.address,
        neighborhood: _neighborhoodFrom(place.addressComponents),
        latitude: place.latLng?.lat,
        longitude: place.latLng?.lng,
        isPreciseAddress: _isPreciseAddress(place),
      );
    } finally {
      // La petición de detalles consume el session token.
      _startNewSession = true;
    }
  }

  /// Primer componente de tipo barrio, del más específico al más genérico.
  static String? _neighborhoodFrom(List<AddressComponent>? components) {
    if (components == null) return null;
    const wanted = ['neighborhood', 'sublocality_level_1', 'sublocality'];
    for (final type in wanted) {
      for (final component in components) {
        if (component.types.contains(type)) return component.name;
      }
    }
    return null;
  }

  static bool _isPreciseAddress(Place place) {
    final types = place.types;
    if (types != null && types.any(_streetPlaceTypes.contains)) return true;
    final components = place.addressComponents;
    if (components == null) return false;
    return components.any(
      (component) =>
          component.types.contains('route') ||
          component.types.contains('street_number'),
    );
  }

  @override
  void endSession() => _startNewSession = true;
}

final placesServiceProvider = Provider<PlacesService>((ref) {
  return GooglePlacesService();
});
