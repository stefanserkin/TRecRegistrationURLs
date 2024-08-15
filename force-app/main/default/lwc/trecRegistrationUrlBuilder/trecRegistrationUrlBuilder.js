import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getBaseUrl from '@salesforce/apex/TRecRegistrationUrlBuilderCtrl.getBaseUrl';
import getAvailableSessions from '@salesforce/apex/TRecRegistrationUrlBuilderCtrl.getAvailableSessions';
import getAvailableLocations from '@salesforce/apex/TRecRegistrationUrlBuilderCtrl.getAvailableLocations';
import userCanGetPublicUrl from '@salesforce/customPermission/Can_Get_Public_URL';

const DAYS_OF_WEEK = [
    { label: 'Sunday', value: 'Sunday' },
    { label: 'Monday', value: 'Monday' },
    { label: 'Tuesday', value: 'Tuesday' },
    { label: 'Wednesday', value: 'Wednesday' },
    { label: 'Thursday', value: 'Thursday' },
    { label: 'Friday', value: 'Friday' },
    { label: 'Saturday', value: 'Saturday' }
];

export default class TrecRegistrationUrlBuilder extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @api registrationUrlPath;

    record;
    recordName;
    error;

    isLoading = false;
    showFilterPanel = false;
    urlIsCopied = false;

    /*************************
     * Wired results and data
     *************************/
    daysOfWeek = DAYS_OF_WEEK;
    wiredRecord = [];
    wiredBaseUrl = [];
    wiredSessions = [];
    wiredLocations = [];
    baseUrl;
    @track sessionOptions;
    @track locationOptions;

    /*************************
     * Selected Filters
     *************************/
    filteredLocation;
    filteredSession;
    filteredStartDate;
    filteredEndDate;
    filteredDays = [];
    filteredAge;

    /*************************
     * Object-Dependent Properties
     *************************/
    objectMap = {
        'TREX1__Program__c': { fields: ['TREX1__Program__c.Name'], filterName: 'program' },
        'TREX1__Course__c': { fields: ['TREX1__Course__c.Name'], filterName: 'course' },
        'TREX1__Course_Session__c': { fields: ['TREX1__Course_Session__c.Name'], filterName: 'courseSession' }
    };

    get recordFields() {
        return this.objectMap[this.objectApiName]?.fields || [];
    }

    get recordFilterName() {
        return this.objectMap[this.objectApiName]?.filterName || '';
    }

    /*************************
     * User Access
     *************************/
    get userHasComponentAccess() {
        return userCanGetPublicUrl;
    }

    /*************************
     * Get Data
     *************************/
    @wire(getRecord, { recordId: '$recordId', fields: '$recordFields' })
    wiredRecordResult(result) {
        this.isLoading = true;
        this.wiredRecord = result;
        if (result.data) {
            this.record = result.data;
            this.error = undefined;
            this.recordName = getFieldValue(this.record, `${this.objectApiName}.Name`);
            this.isLoading = false;
        } else if (result.error) {
            this.record = undefined;
            this.error = result.error;
            this.handleError(this.error);
            this.isLoading = false;
        }
    }

    @wire(getBaseUrl)
    wiredBaseUrlResult(result) {
        this.wiredBaseUrl = result;
        if (result.data) {
            if (this.registrationUrlPath.startsWith('/s')) {
                this.registrationUrlPath = this.registrationUrlPath.substring(2);
            }
            if (!this.registrationUrlPath.startsWith('/')) {
                this.registrationUrlPath = '/' + this.registrationUrlPath;
            }
            this.baseUrl = this.registrationUrlPath
                ? result.data + this.registrationUrlPath
                : result.data;
        } else if (result.error) {
            this.error = result.error;
            this.handleError(this.error);
        }
    }

    @wire(getAvailableLocations)
    wiredLocationResult(result) {
        this.isLoading = true;
        this.wiredLocations = result;
        if (result.data) {
            this.locationOptions = [];
            result.data.forEach(row => {
                this.locationOptions.push({
                     label: row.Name,
                     value: row.Name
                });
            });
            this.isLoading = false;
        } else if (result.error) {
            this.locationOptions = undefined;
            this.error = result.error;
            this.handleError(this.error);
            this.isLoading = false;
        }
    }

    @wire(getAvailableSessions)
    wiredSessionResult(result) {
        this.isLoading = true;
        this.wiredSessions = result;
        if (result.data) {
            this.sessionOptions = [];
            result.data.forEach(row => {
                this.sessionOptions.push({
                    label: row.Name,
                    value: row.Id
               });
            });
            this.isLoading = false;
        } else if (result.error) {
            this.sessionOptions = undefined;
            this.error = result.error;
            this.handleError(this.error);
            this.isLoading = false;
        }
    }

    get sessionIsDisabled() {
        return !this.sessionOptions || this.sessionOptions.length === 0;
    }

    get locationIsDisabled() {
        return !this.locationOptions || this.locationOptions.length === 0;
    }

    /*************************
     * URL Construction
     *************************/
    get url() {
        let result = `${this.baseUrl}?${this.recordFilter}`;
        if (this.filteredLocation) {
            result += `&Location=${encodeURI(this.filteredLocation)}`;
        }
        if (this.hasFilters) {
            result += `&filters=${this.filterString}`;
        }
        return result;
    }

    get recordFilter() {
        return `${this.recordFilterName}=${encodeURI(this.recordName)}`;
    }

    get hasFilters() {
        return this.filteredSession ||
            this.filteredStartDate ||
            this.filteredEndDate ||
            this.filteredDays.length > 0 ||
            this.filteredAge;
    }

    get filterString() {
        let filters = {};
        if (this.filteredSession) {
            filters.session = this.filteredSession;
        }
        if (this.filteredStartDate || this.filteredEndDate) {
            const filteredDateRange = [this.filteredStartDate, this.filteredEndDate];
            filters.dateRange = filteredDateRange;
        }
        if (this.filteredDays.length > 0) {
            filters.daysOfWeek = this.filteredDays;
        }
        if (this.filteredAge) {
            filters.age = this.filteredAge;
        }
        return JSON.stringify(filters);
    }

    /*************************
     * Event Handlers
     *************************/
    handleLocationChange(event) {
        this.filteredLocation = event.detail.value;
    }

    handleSessionChange(event) {
        this.filteredSession = event.detail.value;
    }

    handleStartDateChange(event) {
        this.filteredStartDate = event.detail.value;
    }

    handleEndDateChange(event) {
        this.filteredEndDate = event.detail.value;
    }

    handleDayOfWeekChange(event) {
        this.filteredDays = event.detail.value;
    }
    
    handleAgeChange(event) {
        this.filteredAge = event.detail.value;
    }

    /*************************
     * Actions
     *************************/
    handleToggleFilterPanel() {
        this.showFilterPanel = !this.showFilterPanel;
    }

    handleCopyUrl() {
        if (!this.url) {
            return;
        }

        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(this.url)
                .then(() => {
                    this.showToast('Success', 'URL copied to clipboard', 'success');
                })
                .catch(error => {
                    const errorMessage = error && error.message ? error.message : 'URL could not be copied';
                    this.showToast('Error', errorMessage, 'error');
                });
        } else {
            let input = document.createElement("input");
            input.value = this.url;
            document.body.appendChild(input);
            input.focus();
            input.select();
            document.execCommand("Copy");
            input.remove();
            this.showToast('Success', 'URL copied to clipboard', 'success');
        }

        this.urlIsCopied = true;
        setTimeout(() => {
            this.urlIsCopied = false;
        }, 4000);
    }

    handleGoToUrl() {
        window.open(this.url, '_blank');
    }

    handleRefreshComponent() {
        this.clearFilters();
        refreshApex(this.wiredUrl);
        refreshApex(this.wiredLocations);
        refreshApex(this.wiredSessions);
    }

    clearFilters() {
        this.filteredLocation = undefined;
        this.filteredSession = undefined;
        this.filteredStartDate = undefined;
        this.filteredEndDate = undefined;
        this.filteredDays = [];
        this.filteredAge = undefined;
    }

    /*************************
     * Utils
     *************************/
    handleError(error) {
        let message = 'Unknown error';
        if (Array.isArray(error.body)) {
            message = error.body.map((e) => e.message).join(', ');
        } else if (typeof error.body.message === 'string') {
            message = error.body.message;
        }
        this.showToast('Error', message, 'error');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

}