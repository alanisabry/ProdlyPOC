public class LeanDataCTASchedulable implements Schedulable{

    public LeanDataCTASchedulable () {}

    public void execute(SchedulableContext ctx){
        LeanDataCTABatch customCTABatch = new LeanDataCTABatch();
        Database.executeBatch(customCTABatch, 1);
    }
}