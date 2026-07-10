import 'package:room2gether/core/places/places_service.dart';
import 'package:room2gether/core/utils/normalize_text.dart';

class FakePlacesService implements PlacesService {
  FakePlacesService({
    List<CityPrediction>? predictions,
    List<AddressPrediction>? addressPredictions,
    Map<String, PlaceDetails>? details,
    this.error,
  }) : predictions = predictions ?? seedPredictions,
       addressPredictions = addressPredictions ?? seedAddressPredictions,
       details = details ?? seedDetails;

  final List<CityPrediction> predictions;
  final List<AddressPrediction> addressPredictions;
  final Map<String, PlaceDetails> details;
  final Object? error;

  /// Consultas recibidas, detalles pedidos y sesiones cerradas, para asertar.
  final List<String> queries = [];
  final List<String> detailsFetched = [];
  int sessionsEnded = 0;

  @override
  Future<List<CityPrediction>> autocompleteCities(String query) async {
    queries.add(query);
    if (error != null) throw error!;
    final normalized = normalizeText(query);
    return predictions
        .where(
          (prediction) => normalizeText(prediction.name).contains(normalized),
        )
        .toList();
  }

  @override
  Future<List<AddressPrediction>> autocompleteAddresses(
    String query, {
    String? cityName,
    bool neighborhoodsOnly = false,
  }) async {
    queries.add(query);
    if (error != null) throw error!;
    final normalized = normalizeText(query.split(',').first);
    return addressPredictions
        .where(
          (prediction) => normalizeText(prediction.name).contains(normalized),
        )
        .toList();
  }

  @override
  Future<PlaceDetails> fetchDetails(String placeId) async {
    detailsFetched.add(placeId);
    if (error != null) throw error!;
    final result = details[placeId];
    if (result == null) {
      throw StateError('FakePlacesService: sin detalles para $placeId');
    }
    return result;
  }

  @override
  void endSession() => sessionsEnded++;
}

/// Predicciones tipo de Google Places para tests.
final seedPredictions = [
  const CityPrediction(
    placeId: 'place-vigo',
    name: 'Vigo',
    description: 'Vigo, Pontevedra, España',
  ),
  const CityPrediction(
    placeId: 'place-coruna',
    name: 'A Coruña',
    description: 'A Coruña, España',
  ),
  const CityPrediction(
    placeId: 'place-madrid',
    name: 'Madrid',
    description: 'Madrid, España',
  ),
];

final seedAddressPredictions = [
  const AddressPrediction(
    placeId: 'place-rua-real-12',
    name: 'Rúa Real, 12',
    description: 'Rúa Real, 12, A Coruña, España',
  ),
  const AddressPrediction(
    placeId: 'place-os-castros',
    name: 'Os Castros',
    description: 'Os Castros, A Coruña, España',
  ),
];

final seedDetails = {
  'place-rua-real-12': const PlaceDetails(
    placeId: 'place-rua-real-12',
    formattedAddress: 'Rúa Real 12, 15003 A Coruña, España',
    neighborhood: 'Cidade Vella',
    latitude: 43.3705,
    longitude: -8.3959,
    isPreciseAddress: true,
  ),
  'place-os-castros': const PlaceDetails(
    placeId: 'place-os-castros',
    formattedAddress: 'Os Castros, A Coruña, España',
    neighborhood: 'Os Castros',
    latitude: 43.3623,
    longitude: -8.3907,
    isPreciseAddress: false,
  ),
};
