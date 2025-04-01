public class CurrencyUpdateInvoker {
    @InvocableMethod(label='Invoke Currency Update' description='Triggers currency rate updates for changed records')
    public static void invoke(List<String> currencyCodes) {
        System.enqueueJob(new UpdateCurrencyRates(currencyCodes));
    }

}