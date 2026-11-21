// 1. Recherche les deux catalogues ciblés uniquement lorsqu'ils sont désactivés.
List<Pricebook2> pricebooksToActivate = [
    SELECT Id, Name, IsActive
    FROM Pricebook2
    WHERE Name IN ('Standard Price Book', 'Liste des prix FRANCE')
    AND IsActive = false
];

// Passe leur statut actif à true en mémoire pour préparer la mise à jour.
for (Pricebook2 pb : pricebooksToActivate) {
    pb.IsActive = true;
}

// Met à jour les catalogues uniquement s'il y en a au moins un à activer.
if (!pricebooksToActivate.isEmpty()) {
    update pricebooksToActivate;
    System.debug(pricebooksToActivate.size() + ' catalogue(s) activé(s).');
}

// 2. Recherche les produits désactivés qui possèdent une entrée dans au moins un des deux catalogues.
List<Product2> productsToActivate = [
    SELECT Id, Name, IsActive
    FROM Product2
    WHERE IsActive = false
    AND Id IN (
        SELECT Product2Id
        FROM PricebookEntry
        WHERE Pricebook2.Name IN ('Standard Price Book', 'Liste des prix FRANCE')
    )
];

// Passe leur statut actif à true en mémoire pour préparer la mise à jour.
for (Product2 prod : productsToActivate) {
    prod.IsActive = true;
}

// Met à jour les produits uniquement s'il y en a au moins un à activer.
if (!productsToActivate.isEmpty()) {
    update productsToActivate;
    System.debug(productsToActivate.size() + ' produit(s) activé(s).');
}
