// 1. Activer les catalogues ciblés s'ils sont désactivés
List<Pricebook2> pricebooksToActivate = [
    SELECT Id, Name, IsActive
    FROM Pricebook2
    WHERE Name IN ('Standard Price Book', 'Liste des prix FRANCE')
    AND IsActive = false
];

for (Pricebook2 pb : pricebooksToActivate) {
    pb.IsActive = true;
}

if (!pricebooksToActivate.isEmpty()) {
    update pricebooksToActivate;
    System.debug(pricebooksToActivate.size() + ' catalogue(s) activé(s).');
}

// 2. Activer tous les produits présents dans ces catalogues
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

for (Product2 prod : productsToActivate) {
    prod.IsActive = true;
}

if (!productsToActivate.isEmpty()) {
    update productsToActivate;
    System.debug(productsToActivate.size() + ' produit(s) activé(s).');
}
