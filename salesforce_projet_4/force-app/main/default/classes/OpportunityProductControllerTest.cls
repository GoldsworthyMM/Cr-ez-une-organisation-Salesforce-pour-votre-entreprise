/**
 * Classe de test unitaire pour OpportunityProductController.
 * Vérifie la récupération des lignes, l'indicateur de stock, le cas d'un identifiant null
 * et l'accès en lecture du profil Commercial.
 *
 * @author MM
 * @date 10/11/2026
 */
@IsTest
private class OpportunityProductControllerTest {

    /**
     * Prépare un jeu de données isolé en mémoire avant l'exécution de chaque méthode de test.
     */
    @TestSetup
    static void setupTestData() {
        VitesseTestDataFactory.createOpportunityWithProductLine();
    }

    /**
     * Vérifie que le contrôleur retourne les lignes et les champs attendus lorsque le stock
     * du produit est suffisant pour la quantité de la ligne.
     */
    @IsTest
    static void testGetOpportunityLineItemsReturnsExpectedRecords() {
        // Récupère l'opportunité préparée par les données de test.
        Opportunity opportunity = getTestOpportunity();

        // Démarre la portion du test dont on veut mesurer l'exécution et isoler les limites.
        Test.startTest();
        List<OpportunityLineItem> opportunityLineItems =
            OpportunityProductController.getOpportunityLineItems(opportunity.Id);
        Test.stopTest();

        // Le jeu de test contient une seule ligne pour cette opportunité.
        System.assertEquals(1, opportunityLineItems.size(), 'Une ligne de produit doit être retournée.');

        // La ligne retournée doit être celle du produit créé pour le test.
        System.assertEquals(
            'Tesla Model S Test',
            opportunityLineItems.get(0).Product2.Name,
            'Le nom du produit doit correspondre.'
        );

        // Le contrôleur doit retourner la valeur de stock du produit.
        System.assertEquals(
            10,
            opportunityLineItems.get(0).Product2.QuantityInStock__c,
            'Le stock doit être égal à 10.'
        );

        // Une quantité commandée de 2 sur un stock de 10 ne constitue pas une rupture.
        System.assertEquals(
            false,
            opportunityLineItems.get(0).IsStockInsufficient__c,
            'Le stock étant suffisant (2 <= 10), la formule doit valoir false.'
        );
    }

    /**
     * Vérifie qu'un identifiant null retourne une liste vide.
     */
    @IsTest
    static void testGetOpportunityLineItemsReturnsEmptyForNullId() {
        // Démarre la portion du test portant sur un identifiant d'opportunité null.
        Test.startTest();
        List<OpportunityLineItem> opportunityLineItems =
            OpportunityProductController.getOpportunityLineItems(null);
        Test.stopTest();

        // Sans identifiant d'opportunité, aucune ligne ne doit être retournée.
        System.assertEquals(
            0,
            opportunityLineItems.size(),
            'Une liste vide doit être retournée lorsque l\'identifiant est null.'
        );
    }

    /**
     * Vérifie qu'un Commercial peut lire les lignes de sa propre opportunité.
     * Le test lui attribue la propriété pour ne pas dépendre du partage global de l'organisation.
     */
    @IsTest
    static void testCommercialCanReadOwnedOpportunity() {
        // Crée un utilisateur doté du profil Commercial à l'aide de la factory.
        User commercialUser = VitesseTestDataFactory.createCommercialUser();

        // Récupère l'opportunité de test qui sera attribuée au Commercial.
        Opportunity opportunity = getTestOpportunity();
        opportunity.OwnerId = commercialUser.Id;
        update opportunity;

        // Exécute le scénario en prenant l'identité de l'utilisateur Commercial.
        System.runAs(commercialUser) {
            // Démarre la portion du test dont on veut mesurer l'exécution et isoler les limites.
            Test.startTest();
            List<OpportunityLineItem> opportunityLineItems =
                OpportunityProductController.getOpportunityLineItems(opportunity.Id);
            Test.stopTest();
            
            // Le Commercial propriétaire doit pouvoir consulter la ligne de son opportunité.
            System.assertEquals(
                1,
                opportunityLineItems.size(),
                'Le Commercial doit pouvoir consulter les lignes de sa propre opportunité.'
            );

            // Le champ de stock doit être lisible par ce profil.
            System.assertEquals(
                10,
                opportunityLineItems.get(0).Product2.QuantityInStock__c,
                'Le Commercial doit pouvoir lire le stock.'
            );
        }
    }

    /**
     * Helper de test qui centralise la récupération de l'unique opportunité créée par le jeu de données.
     */
    private static Opportunity getTestOpportunity() {
        return [SELECT Id FROM Opportunity LIMIT 1];
    }
}
