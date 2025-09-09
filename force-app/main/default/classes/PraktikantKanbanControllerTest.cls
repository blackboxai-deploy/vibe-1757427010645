/**
 * Test class for PraktikantKanbanController
 * Tests all methods including permissions, error handling, and bulk operations
 */
@isTest
public class PraktikantKanbanControllerTest {
    
    /**
     * Setup test data
     */
    @testSetup
    static void setupTestData() {
        // Create test Praktikant records
        List<Stundenerfassung_Praktikant__c> testRecords = new List<Stundenerfassung_Praktikant__c>();
        
        // Create records with different statuses
        testRecords.add(new Stundenerfassung_Praktikant__c(
            Name_Anzeige__c = 'Max Mustermann',
            Name_Link__c = 'max.mustermann@example.com',
            Taetigkeit__c = 'Software Development',
            AnwesendheitStatus__c = 'Anwesend'
        ));
        
        testRecords.add(new Stundenerfassung_Praktikant__c(
            Name_Anzeige__c = 'Anna Schmidt',
            Name_Link__c = 'anna.schmidt@example.com',
            Taetigkeit__c = 'Quality Assurance',
            AnwesendheitStatus__c = 'Unentschuldigt'
        ));
        
        testRecords.add(new Stundenerfassung_Praktikant__c(
            Name_Anzeige__c = 'John Doe',
            Name_Link__c = 'john.doe@example.com',
            Taetigkeit__c = 'Data Analysis',
            AnwesendheitStatus__c = 'Entschuldigt'
        ));
        
        insert testRecords;
    }
    
    /**
     * Test successful retrieval of Praktikant records
     */
    @isTest
    static void testGetPraktikantRecordsSuccess() {
        Test.startTest();
        
        List<Stundenerfassung_Praktikant__c> result = PraktikantKanbanController.getPraktikantRecords();
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(3, result.size(), 'Should return 3 test records');
        
        // Check that all required fields are populated
        for (Stundenerfassung_Praktikant__c record : result) {
            System.assertNotEquals(null, record.Name_Anzeige__c, 'Name_Anzeige__c should not be null');
            System.assertNotEquals(null, record.AnwesendheitStatus__c, 'AnwesendheitStatus__c should not be null');
        }
        
        // Verify records are ordered by Name_Anzeige__c
        System.assertEquals('Anna Schmidt', result[0].Name_Anzeige__c, 'First record should be Anna Schmidt');
    }
    
    /**
     * Test successful status update
     */
    @isTest
    static void testUpdatePraktikantStatusSuccess() {
        // Get test record
        Stundenerfassung_Praktikant__c testRecord = [
            SELECT Id, AnwesendheitStatus__c 
            FROM Stundenerfassung_Praktikant__c 
            WHERE Name_Anzeige__c = 'Max Mustermann' 
            LIMIT 1
        ];
        
        Test.startTest();
        
        String result = PraktikantKanbanController.updatePraktikantStatus(
            testRecord.Id, 
            'Unentschuldigt', 
            ''
        );
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('Status successfully updated'), 'Should contain success message');
        
        // Verify the record was updated
        Stundenerfassung_Praktikant__c updatedRecord = [
            SELECT Id, AnwesendheitStatus__c 
            FROM Stundenerfassung_Praktikant__c 
            WHERE Id = :testRecord.Id
        ];
        System.assertEquals('Unentschuldigt', updatedRecord.AnwesendheitStatus__c, 'Status should be updated');
    }
    
    /**
     * Test status update to Entschuldigt with reason
     */
    @isTest
    static void testUpdateStatusToEntschuldigtWithReason() {
        // Get test record
        Stundenerfassung_Praktikant__c testRecord = [
            SELECT Id, AnwesendheitStatus__c 
            FROM Stundenerfassung_Praktikant__c 
            WHERE Name_Anzeige__c = 'Anna Schmidt' 
            LIMIT 1
        ];
        
        String reason = 'Medical appointment';
        
        Test.startTest();
        
        String result = PraktikantKanbanController.updatePraktikantStatus(
            testRecord.Id, 
            'Entschuldigt', 
            reason
        );
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('Status successfully updated'), 'Should contain success message');
        System.assert(result.contains(reason), 'Should contain the reason');
        
        // Verify the record was updated
        Stundenerfassung_Praktikant__c updatedRecord = [
            SELECT Id, AnwesendheitStatus__c 
            FROM Stundenerfassung_Praktikant__c 
            WHERE Id = :testRecord.Id
        ];
        System.assertEquals('Entschuldigt', updatedRecord.AnwesendheitStatus__c, 'Status should be updated');
    }
    
    /**
     * Test error handling for empty record ID
     */
    @isTest
    static void testUpdateStatusEmptyRecordId() {
        Test.startTest();
        
        try {
            PraktikantKanbanController.updatePraktikantStatus('', 'Anwesend', '');
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Record ID cannot be empty'), 'Should throw appropriate error message');
        }
        
        Test.stopTest();
    }
    
    /**
     * Test error handling for empty status
     */
    @isTest
    static void testUpdateStatusEmptyStatus() {
        // Get test record
        Stundenerfassung_Praktikant__c testRecord = [
            SELECT Id 
            FROM Stundenerfassung_Praktikant__c 
            LIMIT 1
        ];
        
        Test.startTest();
        
        try {
            PraktikantKanbanController.updatePraktikantStatus(testRecord.Id, '', '');
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('New status cannot be empty'), 'Should throw appropriate error message');
        }
        
        Test.stopTest();
    }
    
    /**
     * Test error handling for invalid status
     */
    @isTest
    static void testUpdateStatusInvalidStatus() {
        // Get test record
        Stundenerfassung_Praktikant__c testRecord = [
            SELECT Id 
            FROM Stundenerfassung_Praktikant__c 
            LIMIT 1
        ];
        
        Test.startTest();
        
        try {
            PraktikantKanbanController.updatePraktikantStatus(testRecord.Id, 'InvalidStatus', '');
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid status value'), 'Should throw appropriate error message');
        }
        
        Test.stopTest();
    }
    
    /**
     * Test error handling for Entschuldigt without reason
     */
    @isTest
    static void testUpdateStatusEntschuldigtNoReason() {
        // Get test record
        Stundenerfassung_Praktikant__c testRecord = [
            SELECT Id 
            FROM Stundenerfassung_Praktikant__c 
            LIMIT 1
        ];
        
        Test.startTest();
        
        try {
            PraktikantKanbanController.updatePraktikantStatus(testRecord.Id, 'Entschuldigt', '');
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Reason is required'), 'Should throw appropriate error message');
        }
        
        Test.stopTest();
    }
    
    /**
     * Test error handling for non-existent record
     */
    @isTest
    static void testUpdateStatusNonExistentRecord() {
        // Generate a fake ID
        String fakeId = 'a00000000000000';
        
        Test.startTest();
        
        try {
            PraktikantKanbanController.updatePraktikantStatus(fakeId, 'Anwesend', '');
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('not found'), 'Should throw appropriate error message');
        }
        
        Test.stopTest();
    }
    
    /**
     * Test getAnwesendheitStatusOptions method
     */
    @isTest
    static void testGetAnwesendheitStatusOptions() {
        Test.startTest();
        
        List<String> result = PraktikantKanbanController.getAnwesendheitStatusOptions();
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Should return at least one status option');
        
        // Check that expected values are present
        System.assert(result.contains('Unentschuldigt'), 'Should contain Unentschuldigt');
        System.assert(result.contains('Anwesend'), 'Should contain Anwesend');
        System.assert(result.contains('Entschuldigt'), 'Should contain Entschuldigt');
    }
    
    /**
     * Test bulk update functionality
     */
    @isTest
    static void testBulkUpdatePraktikantStatus() {
        // Get test records
        List<Stundenerfassung_Praktikant__c> testRecords = [
            SELECT Id, AnwesendheitStatus__c 
            FROM Stundenerfassung_Praktikant__c 
            LIMIT 2
        ];
        
        // Prepare bulk update data
        List<PraktikantKanbanController.PraktikantStatusUpdate> updates = 
            new List<PraktikantKanbanController.PraktikantStatusUpdate>();
        
        for (Stundenerfassung_Praktikant__c record : testRecords) {
            PraktikantKanbanController.PraktikantStatusUpdate update = 
                new PraktikantKanbanController.PraktikantStatusUpdate();
            update.recordId = record.Id;
            update.newStatus = 'Anwesend';
            updates.add(update);
        }
        
        Test.startTest();
        
        String result = PraktikantKanbanController.bulkUpdatePraktikantStatus(updates);
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('Successfully updated'), 'Should contain success message');
        System.assert(result.contains('2'), 'Should mention 2 updated records');
        
        // Verify records were updated
        List<Stundenerfassung_Praktikant__c> updatedRecords = [
            SELECT Id, AnwesendheitStatus__c 
            FROM Stundenerfassung_Praktikant__c 
            WHERE Id IN :testRecords
        ];
        
        for (Stundenerfassung_Praktikant__c record : updatedRecords) {
            System.assertEquals('Anwesend', record.AnwesendheitStatus__c, 'All records should be updated to Anwesend');
        }
    }
    
    /**
     * Test bulk update with empty list
     */
    @isTest
    static void testBulkUpdateEmptyList() {
        Test.startTest();
        
        try {
            PraktikantKanbanController.bulkUpdatePraktikantStatus(new List<PraktikantKanbanController.PraktikantStatusUpdate>());
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('No updates provided'), 'Should throw appropriate error message');
        }
        
        Test.stopTest();
    }
}