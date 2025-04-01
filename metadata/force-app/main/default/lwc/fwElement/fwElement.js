import { api, LightningElement } from 'lwc';

/*
    Provides some basic features to any component that extends.
    Works in conjunction with fwContainer which acts as parent
    container to receive events for spinner and error handling.
*/
export default class FwElement extends LightningElement {

    hasRendered = false;
    asyncBusyPromises = [];

    //Specifies the fwContainer which handles spinner and errors.
    explicitContainer;
    @api get container() {
        return this.explicitContainer ? this.explicitContainer : this.template.querySelector('c-fw-container');
    }
    set container(value) {
        this.explicitContainer = value;
    }

    //Allows owner to assign a key to the component.
    @api ownerId;

    /*
        Called the first time component is rendered.
    */
    renderedCallback() {

        if (!this.hasRendered) {

            if (this.initCallback) {
                this.initCallback();
            }
            this.hasRendered = true;
            this.dispatchEvent(new CustomEvent('rendered'));

        }

    }

    /*
        Dispatch an event that is meant for the containing fwContainer.
        Non-trivial because, unlike Aura, if this component is actually the fwContainer it will not get a dispatched event.
    */
    dispatchContainerEvent(type, detail, targetContainer) {

        if (targetContainer === false) {
            return;
        }

        let container = targetContainer;
        if (!container) {
            container = this.container;
        }

        if (container) {
            //This is the container itself, dispatch it directly to this component.
            container.dispatchEvent(new CustomEvent(type, {detail: detail}));
        }
        else {
            //This is not the container, dispatch and let the event bubble up.
            this.dispatchEvent(new CustomEvent(type, {bubbles: true, composed: true, detail: detail}));
        }

    }

    /*
        Show confirmation dialog.
    */
    confirm(message, heading, okLabel, cancelLabel, okCallback, cancelCallback) {

        let modalEventDetail = {
            heading: heading ? heading : 'Confirm',
            content: message,
            okLabel: okLabel,
            cancelLabel: cancelLabel,
            okCallback: okCallback,
            cancelCallback: cancelCallback
        };

        //Tell container to display modal with given parameters.
        this.dispatchContainerEvent('modal', modalEventDetail);

    }

    /*
        Call from a catch block to handle an exception. Currently does modal popup with exception info.
        Requires that a containing fwContainer be present, because that's what handles the exception event and shows the modal.
    */
    handleException(e, targetContainer) {
        console.error(e);
        this.dispatchContainerEvent('exception', e, targetContainer);
    }

    /*
        Call to clear any existing exception display, i.e. toast.
    */    
    clearExceptions(code, targetContainer) {
        this.dispatchContainerEvent('clearexceptions', {code: code}, targetContainer);
    }

    /*
        Create an exception marked to be displayed to user, i.e. in a toast rather than unexpected exception.
    */
    newUserException(message, detail, isBlocking) {

        let exception = new Error(message);
        exception.isUserException = true;
        exception.title = detail ? detail.title : undefined;
        exception.code = detail ? detail.code : undefined;
        exception.isBlocking = isBlocking !== undefined ? isBlocking : (detail ? detail.isBlocking : false);
        return exception;

    }

    /*
        Start the spinner.
        Requires containing fwContainer.
    */    
    startWaiting(targetContainer, waitMessage) {

        this.dispatchContainerEvent('startwaiting', waitMessage, targetContainer);

    }

    /*
        Stop the spinner.
        Requires containing fwContainer.
    */
    stopWaiting(targetContainer) {

        this.dispatchContainerEvent('stopwaiting', undefined, targetContainer);

    }

    /*
        Use to call apex or other async method. Handles showing and hiding the spinner as long as there is a containing fwContainer to receive the events.
    */
    callAsync(serviceMethod, objectParameter, targetContainer) {

        return this.callAsyncWithParameters(serviceMethod, [objectParameter], targetContainer);

    }

    /*
        Use to call apex or other async method. Handles showing and hiding the spinner as long as there is a containing fwContainer to receive the events.
    */
    callAsyncWithParameters(serviceMethod, parameterArray, targetContainer) {

        this.startWaiting(targetContainer);

        return new Promise((resolve, reject) => {

            try {

                serviceMethod.apply(this, parameterArray).then(returnValue => {
                    this.stopWaiting(targetContainer);
                    resolve(returnValue);
                })
                .catch(error => {
                    this.stopWaiting(targetContainer);
                    reject(error);
                });

            }
            catch (e) {
                this.stopWaiting(targetContainer);
                throw e;
            }

        });

    }

    /*
        Allows component to declare itself busy with async until the promise resolves.
    */
    setAsyncBusy(promise) {
        this.asyncBusyPromises.push(promise);
        return promise;
    }

    /*
        Removes a previously set busy promise.
    */
    clearAsyncBusy(promise) {
        this.asyncBusyPromises.splice(this.asyncBusyPromises.indexOf(promise), 1);
    }

    /*
        Returns promise that resolves when any and all busy call have been completed.
    */
    @api waitForAsync() {
        return Promise.allSettled(this.asyncBusyPromises);
    }

    /*
        Fire a pubsub event that can be handled by multiple listeners such as sibling components on a flex-page.
    */
    firePubsubEvent(eventName, eventArgs) {

        this.dispatchContainerEvent('firePubsubEvent', {eventName: eventName, eventArgs: eventArgs});

    }

    /*
        Forces the current view to perform a refresh
    */
    refreshView() {
        eval("$A.get('e.force:refreshView').fire();");
    }
}