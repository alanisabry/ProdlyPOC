public class ImportToSalesLoft {

    private final List<sObject> selectedRecords;
    private final List<SObject> records;
    private final String importUrlBase = 'https://app.salesloft.com/app/import/crm?';

    private String filterName = '';
    private List<String> selectedRecordIds = new List<String> {};

    public String importUrl { get { return importUrl(); } }
    public String retUrl { get { return retUrl(); } }

    // The extension constructor initializes the private member
    // variable acct by using the getRecord method from the standard
    // controller.
    public ImportToSalesLoft(ApexPages.StandardController controller) {
        selectedRecords = new List<sObject> { controller.getRecord() };
        records = selectedRecords;

        selectedRecordIds.add(selectedRecords[0].id);
    }

    public ImportToSalesLoft(ApexPages.StandardSetController controller) {
        selectedRecords = controller.getSelected();
        records = controller.getRecords();
        filterName = controller.getFilterId();

        for(sObject selectedRecord : selectedRecords) {
            selectedRecordIds.add(selectedRecord.id);
        }
    }

    public PageReference redirect() {
        return buildPageRef(importUrl());
    }

    public String retUrl() {
        String recordId = getRecordId();
        String objectTypePrefix = recordId.substring(0,3);

        String vfReturnUrl = ApexPages.currentPage().getParameters().get('vfRetURLInSFX');
        if (vfReturnUrl == null) {
            vfReturnUrl = '';
        }

        String originHeader = ApexPages.currentPage().getHeaders().get('Origin');
        if (originHeader == null) {
            originHeader = '';
        }

        String originRedirect = originHeader + '/' + objectTypePrefix + '?fcf=' + filterName;

        if (vfReturnUrl.length() > 0) {
            return vfReturnUrl;
        } else if (filterName.length() > 0) {
            return originRedirect;
        }

        return '';
    }

    private String getRecordId() {
        String recordId = '';
        if (selectedRecords.size() < 1) {
            recordId = records[0].id;
        } else {
            recordId = selectedRecordIds[0];
        }
        return recordId;
    }

    private String importUrl() {
        String queryValue;
        String recordId = getRecordId();
        String objectType = getObjectType(recordId);
        String url = importUrlBase + objectType;

        if (selectedRecords.size() < 1) {
            queryValue = filterName;
            return url + '_listview=' + queryValue;
        }

        queryValue = getQueryObject();
        return url + '=' + queryValue;
    }

    private PageReference buildPageRef(String url) {
        PageReference pageRef = new PageReference(url);
        pageRef.setRedirect(true);
        return pageRef;
    }

    private String getQueryObject() {
        return String.join(selectedRecordIds, ',');
    }

    private String getObjectType(String recordId) {
        String idPrefix = recordId.substring(0, 3);

        return objectTypeMap().get(idPrefix);
    }

    private Map<String, String> objectTypeMap() {
        Map<String, String> m = new Map<String, String>();

        m.put('001', 'account');
        m.put('003', 'contact');
        m.put('00Q', 'lead');

        return m;
    }
}