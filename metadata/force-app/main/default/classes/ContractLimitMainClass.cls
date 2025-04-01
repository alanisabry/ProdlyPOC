public class ContractLimitMainClass {
    @AuraEnabled
    public String limit_Id;
    @AuraEnabled
    public String opportunity_Id;
    @AuraEnabled
    public String oli_Id;
    @AuraEnabled
    public String account_Id;
    @AuraEnabled
    public Date opp_start_date;
    @AuraEnabled
    public Decimal contract_term;
    @AuraEnabled
    public Date opp_end_date;
    @AuraEnabled
    public Integer annual_limit_value;
    @AuraEnabled
    public String limit_type;
    @AuraEnabled
    public Integer qty;
}