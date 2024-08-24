/*
 * MIT License
 * Copyright (c) 2024 Asphalt Green, Inc.
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getBaseUrl from '@salesforce/apex/TRecRegistrationUrlBuilderCtrl.getBaseUrl';
import getAvailableSessions from '@salesforce/apex/TRecRegistrationUrlBuilderCtrl.getAvailableSessions';
import getAvailableLocations from '@salesforce/apex/TRecRegistrationUrlBuilderCtrl.getAvailableLocations';
import getCourseOptions from '@salesforce/apex/TRecRegistrationUrlBuilderCtrl.getCourseOptions';
import getAvailableInstructors from '@salesforce/apex/TRecRegistrationUrlBuilderCtrl.getAvailableInstructors';
import getAvailableGrades from '@salesforce/apex/TRecRegistrationUrlBuilderCtrl.getAvailableGrades';
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
    wiredInstructors = [];
    wiredGrades = [];
    
    baseUrl;
    @track locationOptions;
    @track sessionOptions;
    @track courseOptionOptions;
    @track instructorOptions;
    @track gradeOptions;
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
            'startTime': null,
            'endTime': null,
            'dayOfWeek': [],
            'age': undefined,
            'courseOptionId': undefined,
            'showUnavailableCourseOptions': false,
            'instructor': undefined,
            'grade': undefined
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
            const communityUrl = result.data;
            this.baseUrl = this.constructBaseUrl(communityUrl);
        } else if (result.error) {
            this.error = result.error;
            this.handleError(this.error);
        }
    }

    constructBaseUrl(communityUrl) {
        let result = communityUrl ? communityUrl : '';
    
        if (this.registrationUrlPath) {
            const regEx = new RegExp('^(?:[a-z+]+:)?//', 'i');
            if (regEx.test(this.registrationUrlPath)) {
                return this.registrationUrlPath;
            }

            if (!this.registrationUrlPath.startsWith('/')) {
                this.registrationUrlPath = '/' + this.registrationUrlPath;
            }
            if (this.registrationUrlPath.startsWith('/s/')) {
                this.registrationUrlPath = this.registrationUrlPath.substring(2);
            }
            result += this.registrationUrlPath;
        }
        return result;
    }

    @wire(getAvailableLocations)
    wiredLocationResult(result) {
        this.isLoading = true;
        this.wiredLocations = result;
        if (result.data) {
            this.locationOptions = result.data;
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
            this.sessionOptions = result.data;
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
                this.courseOptionOptions = result.data;
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

    @wire(getAvailableInstructors, {recordId: '$recordId'})
    wiredInstructorResult(result) {
        this.isLoading = true;
        this.wiredInstructors = result;
        if (result.data) {
            this.instructorOptions = result.data;
            this.isLoading = false;
        } else if (result.error) {
            this.instructorOptions = undefined;
            this.error = result.error;
            this.handleError(this.error);
            this.isLoading = false;
        }
    }

    @wire(getAvailableGrades)
    wiredGradeResult(result) {
        this.isLoading = true;
        this.wiredGrades = result;
        if (result.data) {
            this.gradeOptions = result.data;
            this.isLoading = false;
        } else if (result.error) {
            this.gradeOptions = undefined;
            this.error = result.error;
            this.isLoading = false;
        }
    }

    get sessionIsDisabled() {
        return this.isLoading || !this.sessionOptions || this.sessionOptions.length === 0;
    }

    get locationIsDisabled() {
        return this.isLoading || !this.locationOptions || this.locationOptions.length === 0;
    }

    get courseOptionIdIsDisabled() {
        return this.isLoading || !this.courseOptionOptions || this.courseOptionOptions.length === 0;
    }

    get instructorIsDisabled() {
        return this.isLoading || !this.instructorOptions || this.instructorOptions.length === 0;
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
            this.filters.startTime ||
            this.filters.endTime ||
            this.filters.dayOfWeek.length > 0 ||
            this.filters.age ||
            this.filters.instructor ||
            this.filters.grade;
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
        if (filters.startTime || filters.endTime) {
            const timeRange = [filters.startTime, filters.endTime];
            urlFilters.timeRange = timeRange;
        }
        if (filters.dayOfWeek.length > 0) {
            urlFilters.dayOfWeek = filters.dayOfWeek;
        }
        if (filters.age) {
            urlFilters.age = filters.age;
        }
        if (filters.instructor) {
            urlFilters.instructor = encodeURI(filters.instructor);
        }
        if (filters.grade) {
            urlFilters.grade = encodeURI(filters.grade);
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
        refreshApex(this.wiredBaseUrl);
        refreshApex(this.wiredLocations);
        refreshApex(this.wiredSessions);
        refreshApex(this.wiredCourseOptions);
        refreshApex(this.wiredInstructors);
        refreshApex(this.wiredGrades);
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