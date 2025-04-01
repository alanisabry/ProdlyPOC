public without sharing class SPGOpportunityController {
    @AuraEnabled
    public static Model getModel(String opportunityId) {
        try {
            Opportunity opportunity = getOpportunity(opportunityId);
            List<Opportunity_Competitors__c> competitors = getOpportunityCompetitors(opportunity);
            List<Opportunity_Competitors__c> currentVendors = getOpportunityCurrentVendors(opportunity);
            List<OpportunityPartner> partners = getPartners(opportunity);
            List<OpportunityContactRole> contactRoles = getOpportunityContactRoles(opportunity);
            List<Object_Info_Setting__mdt> objectInfoSettings = SPGUtillity.getObjectInfoSettings(null, opportunity.RecordType.DeveloperName);
            return new Model(opportunity, competitors, currentVendors, partners, contactRoles, objectInfoSettings);
        } catch (QueryException e) {
            throw new FW_Exception('Invalid record id or missing configuration for record type.', true, e.getStackTraceString());
        } catch (Exception e) {
            throw new FW_Exception(e.getMessage(), true, e.getStackTraceString());
        }
    }

    private static Opportunity getOpportunity(String opportunityId) {
        return [SELECT Id, AccountId, Account.RecordType.DeveloperName, RecordType.DeveloperName FROM Opportunity WHERE Id = :opportunityId WITH SECURITY_ENFORCED LIMIT 1];
    }

    private static List<Opportunity_Competitors__c> getOpportunityCompetitors(Opportunity opportunity) {
        return [
            SELECT
                Id,
                Opportunity__c,
                Competitor_name_if_Other__c,
                Competitor__c,
                Is_this_the_current_tool_in_use__c,
                Did_this_competitor_win_the_account__c,
                Product_Reason__c,
                Reason__c,
                Details__c
            FROM Opportunity_Competitors__c
            WHERE Opportunity__c = :opportunity.Id
            AND   Is_this_the_current_tool_in_use__c != 'Yes' 
            WITH SECURITY_ENFORCED
        ];
    }

    private static List<Opportunity_Competitors__c> getOpportunityCurrentVendors(Opportunity opportunity) {
        return [
            SELECT
                Id,
                Opportunity__c,
                Competitor_name_if_Other__c,
                Competitor__c,
                Is_this_the_current_tool_in_use__c,
                Did_this_competitor_win_the_account__c,
                Product_Reason__c,
                Reason__c,
                Details__c
            FROM Opportunity_Competitors__c
            WHERE Opportunity__c = :opportunity.Id
            AND   Is_this_the_current_tool_in_use__c = 'Yes' 
            WITH SECURITY_ENFORCED
        ];
    }

    private static List<OpportunityPartner> getPartners(Opportunity opportunity) {
        return [
            SELECT Id, AccountToId, AccountTo.Name, IsPrimary, Role
            FROM OpportunityPartner
            WHERE OpportunityId = :opportunity.Id AND AccountToId = :opportunity.AccountId
        ];
    }

    private static List<OpportunityContactRole> getOpportunityContactRoles(Opportunity opportunity) {
        return [SELECT Id, ContactId, Contact.Name, Role, IsPrimary FROM OpportunityContactRole WHERE OpportunityId = :opportunity.Id WITH SECURITY_ENFORCED];
    }

    public class Model {
        @AuraEnabled
        public String opportunityId { get; set; }
        @AuraEnabled
        public String opportunityRecordType { get; set; }
        @AuraEnabled
        public Set<String> opportunityFields { get; set; }
        @AuraEnabled
        public Set<String> opportunityNewBusinessFields { get; set; }
        @AuraEnabled
        public Integer opportunityColumns { get; set; }
        @AuraEnabled
        public Set<String> spicedFields { get; set; }
        @AuraEnabled
        public Integer spicedColumns { get; set; }
        @AuraEnabled
        public String accountId { get; set; }
        @AuraEnabled
        public Set<String> accountFields { get; set; }
        @AuraEnabled
        public Integer accountColumns { get; set; }
        @AuraEnabled
        public List<Opportunity_Competitors__c> competitors { get; set; }
        @AuraEnabled
        public Set<String> competitorFields { get; set; }
        @AuraEnabled
        public Integer competitorColumns { get; set; }
        @AuraEnabled
        public List<OpportunityPartner> partners { get; set; }
        @AuraEnabled
        public Set<String> partnerFields { get; set; }
        @AuraEnabled
        public Integer partnerColumns { get; set; }
        @AuraEnabled
        public List<OpportunityContactRole> contactRoles { get; set; }
        @AuraEnabled
        public Set<String> contactRoleFields { get; set; }
        @AuraEnabled
        public Integer contactRoleColumns { get; set; }
        @AuraEnabled
        public List<Opportunity_Competitors__c> currentVendors { get; set; }
        @AuraEnabled
        public Set<String> newBusinessTeamFields { get; set; }
        @AuraEnabled
        public Integer oppTeamColumns { get; set; }
        @AuraEnabled
        public Set<String> newBusinessSolutionsFields { get; set; }
        @AuraEnabled
        public Integer oppSolutionsColumns { get; set; }

        public Model() {
            this.opportunityFields = new Set<String>();
            this.opportunityNewBusinessFields = new Set<String>();
            this.opportunityColumns = 1;
            this.spicedFields = new Set<String>();
            this.spicedColumns = 1;
            this.accountFields = new Set<String>();
            this.accountColumns = 1;
            this.competitors = new List<Opportunity_Competitors__c>();
            this.currentVendors = new List<Opportunity_Competitors__c>();
            this.competitorFields = new Set<String>();
            this.competitorColumns = 1;
            this.partners = new List<OpportunityPartner>();
            this.partnerFields = new Set<String>();
            this.partnerColumns = 1;
            this.contactRoles = new List<OpportunityContactRole>();
            this.contactRoleFields = new Set<String>();
            this.contactRoleColumns = 1;
            this.newBusinessTeamFields = new Set<String>();
            this.oppTeamColumns = 1;
            this.newBusinessSolutionsFields = new Set<String>();
            this.oppSolutionsColumns = 1;
        }

        public Model(
            Opportunity opportunity,
            List<Opportunity_Competitors__c> competitors,
            List<Opportunity_Competitors__c> currentVendors,
            List<OpportunityPartner> partners,
            List<OpportunityContactRole> contactRoles,
            List<Object_Info_Setting__mdt> objectInfoSettings
        ) {
            Map<String, Object_Info_Setting__mdt> objectInfoSettingsByName = new Map<String, Object_Info_Setting__mdt>();
            for (Object_Info_Setting__mdt objectInfoSetting : objectInfoSettings) {
                objectInfoSettingsByName.put(objectInfoSetting.DeveloperName, objectInfoSetting);
            }

            String oppKeyPrefix;
            switch on opportunity.RecordType.DeveloperName {
                when 'Default_Opportunity_Record_Type' {
                    oppKeyPrefix = 'Opp_New_Business';
                }
                when 'Professional_Services_Opportunities' {
                    oppKeyPrefix = 'Opp_Professional_Services';
                }
                when 'Referral' {
                    oppKeyPrefix = 'Opp_Referral';
                }
                when 'Referral_Closed' {
                    oppKeyPrefix = 'Opp_Referral';
                }
                when 'Renewal_Record_Type' {
                    oppKeyPrefix = 'Opp_Renewal';
                }
                when 'Upsell_Record_Type' {
                    oppKeyPrefix = 'Opp_Upsell';
                }
            }

            this.opportunityId = opportunity.Id;
            this.opportunityRecordType = opportunity.RecordType.DeveloperName;
            this.opportunityFields = getFields(objectInfoSettingsByName.get(oppKeyPrefix));
            this.opportunityColumns = getColumns(objectInfoSettingsByName.get(oppKeyPrefix));
            this.spicedFields = getFields(objectInfoSettingsByName.get(oppKeyPrefix + '_Spiced'));
            this.spicedColumns = getColumns(objectInfoSettingsByName.get(oppKeyPrefix + '_Spiced'));
            this.accountId = opportunity.AccountId;
            if (oppKeyPrefix == 'Opp_New_Business') {
                this.opportunityNewBusinessFields = getFields(objectInfoSettingsByName.get(oppKeyPrefix + '_Account'));
                this.newBusinessTeamFields = getFields(objectInfoSettingsByName.get(oppKeyPrefix + '_Opp_Teams'));
                this.newBusinessSolutionsFields = getFields(objectInfoSettingsByName.get(oppKeyPrefix + '_Solutions_Scope'));
                this.oppTeamColumns = getColumns(objectInfoSettingsByName.get(oppKeyPrefix + '_Opp_Teams'));
                this.oppSolutionsColumns = getColumns(objectInfoSettingsByName.get(oppKeyPrefix + '_Solutions_Scope'));
            }
            this.accountFields = getFields(objectInfoSettingsByName.get('Account_' + opportunity.Account.RecordType.DeveloperName));
            this.accountColumns = getColumns(objectInfoSettingsByName.get(oppKeyPrefix + '_Account'));

            this.competitors = !competitors.isEmpty() ? competitors : new List<Opportunity_Competitors__c>();
            this.competitorFields = getFields(objectInfoSettingsByName.get(oppKeyPrefix + '_Competitors'));
            this.competitorColumns = getColumns(objectInfoSettingsByName.get(oppKeyPrefix + '_Competitors'));

            this.currentVendors = !currentVendors.isEmpty() ? currentVendors : new List<Opportunity_Competitors__c>();
        
            this.partners = !partners.isEmpty() ? partners : new List<OpportunityPartner>();
            this.partnerFields = getFields(objectInfoSettingsByName.get(oppKeyPrefix + '_Partners'));
            this.partnerColumns = getColumns(objectInfoSettingsByName.get(oppKeyPrefix + '_Partners'));
            
            this.contactRoles = !contactRoles.isEmpty() ? contactRoles : new List<OpportunityContactRole>();
            this.contactRoleFields = getFields(objectInfoSettingsByName.get(oppKeyPrefix + '_Contacts'));
            this.contactRoleColumns = getColumns(objectInfoSettingsByName.get(oppKeyPrefix + '_Contacts'));
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