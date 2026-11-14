/**
 * Fabrique des données de test réutilisables pour l'application Vitesse.
 *
 * @author MM
 * @date 10/11/2026
 */
@IsTest
public class VitesseTestDataFactory {

    /**
     * Crée et insère un utilisateur de test doté du profil Commercial.
     */
    public static User createCommercialUser() {
        Profile commercialProfile = [SELECT Id FROM Profile WHERE Name = 'Commercial' LIMIT 1];
        User commercialUser = new User(
            Alias = 'commtest',
            Email = 'commercial.test@vitesse-test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Commercial',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = commercialProfile.Id,
            TimeZoneSidKey = 'Europe/Paris',
            UserName = 'commercial.test.' + System.currentTimeMillis() + '@vitesse-test.com'
        );
        insert commercialUser;
        return commercialUser;
    }

    /**
     * Crée et insère un produit de test.
     *
     * @param productName Nom du produit
     * @param stockQuantity Quantité initiale en stock
     * @return Le produit inséré
     */
    public static Product2 createTestProduct(String productName, Decimal stockQuantity) {
        Product2 testProduct = new Product2(
            Name = productName,
            IsActive = true,
            QuantityInStock__c = stockQuantity
        );
        insert testProduct;
        return testProduct;
    }

    /**
     * Crée et insère une entrée du catalogue de prix standard pour un produit.
     *
     * @param productId Identifiant du produit à associer
     * @param unitPrice Prix unitaire
     * @return L'entrée du catalogue insérée
     */
    public static PricebookEntry createStandardPricebookEntry(Id productId, Decimal unitPrice) {
        PricebookEntry standardPricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = productId,
            UnitPrice = unitPrice,
            IsActive = true
        );
        insert standardPricebookEntry;
        return standardPricebookEntry;
    }

    /**
     * Crée et insère une opportunité associée au catalogue de prix fourni.
     *
     * @param pricebookId Identifiant du catalogue de prix
     * @return L'opportunité insérée
     */
    public static Opportunity createTestOpportunity(Id pricebookId) {
        Opportunity testOpportunity = new Opportunity(
            Name = 'Opportunité Vitesse Test',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = pricebookId
        );
        insert testOpportunity;
        return testOpportunity;
    }

    /**
     * Crée et insère une ligne de produit sur une opportunité.
     *
     * @param opportunityId Identifiant de l'opportunité
     * @param pricebookEntryId Identifiant de l'entrée du catalogue de prix
     * @param quantity Quantité commandée
     * @param unitPrice Prix unitaire de la ligne
     * @return La ligne de produit insérée
     */
    public static OpportunityLineItem createTestOpportunityLineItem(
        Id opportunityId,
        Id pricebookEntryId,
        Decimal quantity,
        Decimal unitPrice
    ) {
        OpportunityLineItem testOpportunityLineItem = new OpportunityLineItem(
            OpportunityId = opportunityId,
            PricebookEntryId = pricebookEntryId,
            Quantity = quantity,
            UnitPrice = unitPrice
        );
        insert testOpportunityLineItem;
        return testOpportunityLineItem;
    }

    /**
     * Crée un produit en stock, son prix standard et une opportunité avec une ligne de produit.
     *
     * @return L'opportunité créée avec sa ligne de produit de test
     */
    public static Opportunity createOpportunityWithProductLine() {
        Product2 testProduct = createTestProduct('Tesla Model S Test', 10);
        PricebookEntry standardPricebookEntry =
            createStandardPricebookEntry(testProduct.Id, 80000);
        Opportunity testOpportunity =
            createTestOpportunity(Test.getStandardPricebookId());
        createTestOpportunityLineItem(
            testOpportunity.Id,
            standardPricebookEntry.Id,
            2,
            80000
        );
        return testOpportunity;
    }
}
