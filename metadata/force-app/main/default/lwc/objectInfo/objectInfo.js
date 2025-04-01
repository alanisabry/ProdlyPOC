import {LightningElement, api} from 'lwc';
export default class ObjectInfo extends LightningElement {

    @api objDef = {
        "fields" : [
            { "id":"id", "label":"Id", "value":"ABC123", "type":"string", "visible":"false"},
            { "name":"name", "label":"Name", "value":"JLW Test 001", "type":"string", "visible":"true"}
        ]
    }
}