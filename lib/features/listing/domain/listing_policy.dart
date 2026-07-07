/// Regla de negocio de CU-06: "No tiene ninguna publicación activa" como
/// precondición para crear una publicación.
///
/// Se comprueba SOLO en la app (decisión acordada: sin constraint en BD) y
/// está centralizada aquí a propósito: si en el futuro se permite más de una
/// publicación activa por usuario, basta con cambiar esta constante (o la
/// función) sin tocar pantallas, controllers ni repositorios.
const int maxActiveListingsPerUser = 1;

bool canCreateListing({required int activeListingsCount}) {
  return activeListingsCount < maxActiveListingsPerUser;
}
