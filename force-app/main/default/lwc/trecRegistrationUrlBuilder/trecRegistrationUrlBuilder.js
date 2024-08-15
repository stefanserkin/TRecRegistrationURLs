import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getBaseUrl from '@salesforce/apex/TRecRegistrationUrlBuilderCtrl.getBaseUrl';
import getAvailableSessions from '@salesforce/apex/TRecRegistrationUrlBuilderCtrl.getAvailableSessions';
import getAvailableLocations from '@salesforce/apex/TRecRegistrationUrlBuilderCtrl.getAvailableLocations';
import getCourseOptions from '@salesforce/apex/TRecRegistrationUrlBuilderCtrl.getCourseOptions';
import userCanGetPublicUrl from '@salesforce/customPermission/Can_Get_Public_Registration_URL';

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
    wiredRecord = [];
    wiredBaseUrl = [];
    wiredLocations = [];
    wiredSessions = [];
    wiredCourseOptions = [];
    
    baseUrl;
    @track locationOptions;
    @track sessionOptions;
    @track courseOptionOptions;
    daysOfWeek = DAYS_OF_WEEK;

    /*************************
     * Selected Filters
     *************************/
    @track filters = this.emptyFilters;

    get emptyFilters() {
        return {
            'Location': undefined,
            'session': undefined,
            'startDate': undefined,
            'endDate': undefined,
            'dayOfWeek': [],
            'age': undefined,
            'courseOptionId': undefined,
            'showUnavailableCourseOptions': false
        };
    }

    /*************************
     * Object-Dependent Properties
     *************************/
    objectMap = {
        'TREX1__Program__c': { 
            fields: ['TREX1__Program__c.Name'], 
            filterName: 'program' 
        },
        'TREX1__Course__c': { 
            fields: ['TREX1__Course__c.Name'], 
            filterName: 'course' 
        },
        'TREX1__Course_Session__c': { 
            fields: ['TREX1__Course_Session__c.Name'], 
            filterName: 'courseSession' 
        }
    };

    get recordFields() {
        return this.objectMap[this.objectApiName]?.fields || [];
    }

    get recordFilterName() {
        return this.objectMap[this.objectApiName]?.filterName || '';
    }

    get isCourseSession() {
        return this.objectApiName && this.objectApiName === 'TREX1__Course_Session__c';
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
            let url = result.data;
            if (this.registrationUrlPath) {
                if (!this.registrationUrlPath.startsWith('/')) {
                    this.registrationUrlPath = '/' + this.registrationUrlPath;
                }
                if (this.registrationUrlPath.startsWith('/s/')) {
                    this.registrationUrlPath = this.registrationUrlPath.substring(2);
                }
                url += this.registrationUrlPath;
            }
            this.baseUrl = url;
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

    @wire(getCourseOptions, {courseSessionId: '$recordId', showUnavailable: '$filters.showUnavailableCourseOptions'})
    wiredCourseOptions(result) {
        this.isLoading = true;
        this.wiredCourseOptions = result;
        if (this.isCourseSession) {
            if (result.data) {
                this.courseOptionOptions = result.data.map(row => ({
                    label: row.Name,
                    value: row.Id
                }));
                this.isLoading = false;
            } else if (result.error) {
                this.courseOptionOptions = undefined;
                this.error = result.error;
                this.handleError(this.error);
                this.isLoading = false;
            }
        } else {
            this.isLoading = false;
        }
    }

    get sessionIsDisabled() {
        return !this.sessionOptions || this.sessionOptions.length === 0;
    }

    get locationIsDisabled() {
        return !this.locationOptions || this.locationOptions.length === 0;
    }

    get courseOptionIdIsDisabled() {
        return !this.courseOptionOptions || this.courseOptionOptions.length === 0;
    }

    /*************************
     * URL Construction
     *************************/
    get url() {
        return this.isCourseSession ? this.deepLinkUrl : this.filteredUrl;
    }

    get deepLinkUrl() {
        let url = `${this.baseUrl}?courseSessionId=${this.recordId}`;
        if (this.filters.courseOptionId) {
            url += `&courseOptionId=${this.filters.courseOptionId}`;
        }
        return url;
    }

    get filteredUrl() {
        let result = `${this.baseUrl}?${this.recordFilterName}=${encodeURI(this.recordName)}`;
        if (this.filters.Location) {
            result += `&Location=${encodeURI(this.filters.Location)}`;
        }
        if (this.hasFilters) {
            result += `&filters=${this.filterString}`;
        }
        return result;
    }

    get hasFilters() {
        return this.filters.session ||
            this.filters.startDate ||
            this.filters.endDate ||
            this.filters.dayOfWeek.length > 0 ||
            this.filters.age;
    }

    get filterString() {
        let urlFilters = {};
        const filters = this.filters;
        if (filters.session) {
            urlFilters.session = filters.session;
        }
        if (filters.startDate || filters.endDate) {
            const dateRange = [filters.startDate, filters.endDate];
            urlFilters.dateRange = dateRange;
        }
        if (filters.dayOfWeek.length > 0) {
            urlFilters.dayOfWeek = filters.dayOfWeek;
        }
        if (filters.age) {
            urlFilters.age = this.filters.age;
        }
        return JSON.stringify(urlFilters);
    }

    /*************************
     * Event Handlers
     *************************/
    handleFilterChange(event) {
        const changedFilter = event.target.name;
        if (event.target.type === 'checkbox') {
            this.filters[changedFilter] = event.target.checked;
        } else {
            this.filters[changedFilter] = event.detail.value;
        }
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
        this.filters = this.emptyFilters;
        refreshApex(this.wiredUrl);
        refreshApex(this.wiredLocations);
        refreshApex(this.wiredSessions);
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