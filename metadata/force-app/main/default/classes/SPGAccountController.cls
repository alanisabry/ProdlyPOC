public without sharing class SPGAccountController {
    @AuraEnabled
    public static Model getModel(String accountId) {
        try {
            Account account = [SELECT Id, RecordType.DeveloperName FROM Account WHERE Id = :accountId WITH SECURITY_ENFORCED LIMIT 1];
            List<Object_Info_Setting__mdt> objectInfoSettings = SPGUtillity.getObjectInfoSettings('Account', account.RecordType.DeveloperName);
            List<Adjacent_Technology__c> technologies = getAdjacentTechnologies(account);
            return new Model(account, objectInfoSettings, technologies);
        } catch (QueryException e) {
            throw new FW_Exception('Invalid record id or missing configuration for record type.', true, e.getStackTraceString());
        } catch (Exception e) {
            throw new FW_Exception(e.getMessage(), true, e.getStackTraceString());
        }
    }

    private static List<Adjacent_Technology__c> getAdjacentTechnologies(Account a){
        return [
            SELECT Id
            FROM Adjacent_Technology__c
            WHERE Account__c =: a.Id
            WITH SECURITY_ENFORCED
        ];
    }

    public class Model {
        @AuraEnabled
        public String accountId { get; set; }
        @AuraEnabled
        public List<String> accountFields { get; set; }
        @AuraEnabled
        public Integer accountColumns { get; set; }
        @AuraEnabled
        public List<String> addressesFields { get; set; }
        @AuraEnabled
        public Integer addressesColumns { get; set; }
        @AuraEnabled
        public List<Adjacent_Technology__c> technologies { get; set; }
        @AuraEnabled
        public Map<String, Set<String>> technologyFields { get; set; }
        @AuraEnabled
        public Integer technologyColumns { get; set; }

        public Model() {
            this.accountFields = new List<String>();
            this.accountColumns = 1;
            this.addressesFields = new List<String>();
            this.addressesColumns = 1;
            this.technologyFields = new Map<String, Set<String>>();
        }

        public Model(Account account, List<Object_Info_Setting__mdt> objectInfoSettings, List<Adjacent_Technology__c> technologies) {
            this();
            Map<String, Object_Info_Setting__mdt> objectInfoSettingsByName = new Map<String, Object_Info_Setting__mdt>();
            for (Object_Info_Setting__mdt objectInfoSetting : objectInfoSettings) {
                objectInfoSettingsByName.put(objectInfoSetting.DeveloperName, objectInfoSetting);
            }

            String keyPrefix;
            switch on account.RecordType.DeveloperName {
                when 'Customer' {
                    keyPrefix = 'Account_Customer';
                }
                when 'Gartner_Buyer_Discovery' {
                    keyPrefix = 'Account_Buyer';
                }
                when 'Partner' {
                    keyPrefix = 'Account_Partner';
                }
                when 'Prospect' {
                    keyPrefix = 'Account_Prospect';
                }
                when 'Webdam' {
                    keyPrefix = 'Account_Webdam';
                }
            }

            this.accountId = account.Id;
            this.accountFields = objectInfoSettingsByName.get(keyPrefix).Fields__c.remove(' ').split(',');
            this.accountColumns = Integer.valueOf(objectInfoSettingsByName.get(keyPrefix).Display_Columns__c);
            this.addressesFields = objectInfoSettingsByName.get(keyPrefix + '_Addresses').Fields__c.remove(' ').split(',');
            this.addressesColumns = Integer.valueOf(objectInfoSettingsByName.get(keyPrefix + '_Addresses').Display_Columns__c);
            
            this.technologies = !technologies.isEmpty()? technologies : new List<Adjacent_Technology__c>();
            this.technologyFields.put('Adjacent Technology Details', getFields(objectInfoSettingsByName.get(keyPrefix + '_Technologies')));
            this.technologyFields.put('Confirmed Integration Details', getFields(objectInfoSettingsByName.get(keyPrefix + '_Integration')));
            this.technologyColumns = getColumns(objectInfoSettingsByName.get(keyPrefix + '_Technologies'));
        }

        private Set<String> getFields(Object_Info_Setting__mdt objectInfoSettings) {
            Set<String> fields = new Set<String>();
            for (String field : objectInfoSettings.Fields__c.remove(' ').split(',')) {
                fields.add(field);
            }
            return fields;
        }

        private Integer getColumns(Object_Info_Setting__mdt objectInfoSettings) {
            return Integer.valueOf(objectInfoSettings.Display_Columns__c);
        }
    }
}