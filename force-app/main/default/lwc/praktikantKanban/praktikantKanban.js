import { LightningElement, wire, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getPraktikantRecords from '@salesforce/apex/PraktikantKanbanController.getPraktikantRecords';
import updatePraktikantStatus from '@salesforce/apex/PraktikantKanbanController.updatePraktikantStatus';

export default class PraktikantKanban extends LightningElement {
    @track praktikantRecords = [];
    @track isLoading = true;
    @track showReasonModal = false;
    @track reasonText = '';
    @track draggedRecordId = null;
    @track draggedRecord = {};
    @track targetStatus = '';
    @track isDragging = false;
    @track touchStartX = 0;
    @track touchStartY = 0;
    @track touchCurrentX = 0;
    @track touchCurrentY = 0;
    
    // Wired method to get praktikant records
    wiredPraktikantRecords;
    
    @wire(getPraktikantRecords)
    wiredPraktikants(result) {
        this.wiredPraktikantRecords = result;
        if (result.data) {
            this.praktikantRecords = result.data;
            this.isLoading = false;
        } else if (result.error) {
            this.showToast('Error', 'Failed to load praktikant records: ' + result.error.body.message, 'error');
            this.isLoading = false;
        }
    }

    // Computed properties for filtered records
    get unentschuldigtRecords() {
        return this.praktikantRecords.filter(record => record.AnwesendheitStatus__c === 'Unentschuldigt');
    }

    get anwesendRecords() {
        return this.praktikantRecords.filter(record => record.AnwesendheitStatus__c === 'Anwesend');
    }

    get entschuldigtRecords() {
        return this.praktikantRecords.filter(record => record.AnwesendheitStatus__c === 'Entschuldigt');
    }

    // Computed properties for record counts
    get unentschuldigtCount() {
        return this.unentschuldigtRecords.length;
    }

    get anwesendCount() {
        return this.anwesendRecords.length;
    }

    get entschuldigtCount() {
        return this.entschuldigtRecords.length;
    }

    // Computed properties for empty states
    get showUnentschuldigtEmpty() {
        return this.unentschuldigtRecords.length === 0 && !this.isLoading;
    }

    get showAnwesendEmpty() {
        return this.anwesendRecords.length === 0 && !this.isLoading;
    }

    get showEntschuldigtEmpty() {
        return this.entschuldigtRecords.length === 0 && !this.isLoading;
    }

    // Check if reason is empty
    get isReasonEmpty() {
        return !this.reasonText || this.reasonText.trim().length === 0;
    }

    // Touch helper style for mobile dragging
    get touchHelperStyle() {
        return `position: fixed; top: ${this.touchCurrentY - 50}px; left: ${this.touchCurrentX - 100}px; pointer-events: none; z-index: 9999;`;
    }

    // Drag and Drop Event Handlers
    handleDragStart(event) {
        const recordId = event.target.dataset.recordId;
        const currentStatus = event.target.dataset.currentStatus;
        
        this.draggedRecordId = recordId;
        this.draggedRecord = this.praktikantRecords.find(record => record.Id === recordId);
        
        event.dataTransfer.setData('text/plain', recordId);
        event.dataTransfer.setData('application/json', JSON.stringify({
            recordId: recordId,
            currentStatus: currentStatus
        }));
        
        // Add visual feedback
        event.target.classList.add('dragging');
    }

    handleDragEnd(event) {
        event.target.classList.remove('dragging');
        this.draggedRecordId = null;
        this.draggedRecord = {};
    }

    handleDragOver(event) {
        event.preventDefault();
    }

    handleDragEnter(event) {
        event.preventDefault();
        if (event.currentTarget.classList.contains('kanban-column')) {
            event.currentTarget.classList.add('drag-over');
        }
    }

    handleDragLeave(event) {
        if (event.currentTarget.classList.contains('kanban-column')) {
            event.currentTarget.classList.remove('drag-over');
        }
    }

    handleDrop(event) {
        event.preventDefault();
        event.currentTarget.classList.remove('drag-over');
        
        const dropData = JSON.parse(event.dataTransfer.getData('application/json'));
        const newStatus = event.currentTarget.dataset.status;
        
        if (dropData.currentStatus !== newStatus) {
            this.processStatusChange(dropData.recordId, newStatus, dropData.currentStatus);
        }
    }

    // Touch Event Handlers for Mobile/Tablet Support
    handleTouchStart(event) {
        const touch = event.touches[0];
        this.touchStartX = touch.clientX;
        this.touchStartY = touch.clientY;
        this.touchCurrentX = touch.clientX;
        this.touchCurrentY = touch.clientY;
        
        const recordId = event.target.closest('[data-record-id]').dataset.recordId;
        const currentStatus = event.target.closest('[data-current-status]').dataset.currentStatus;
        
        this.draggedRecordId = recordId;
        this.draggedRecord = this.praktikantRecords.find(record => record.Id === recordId);
        
        // Add visual feedback
        event.target.closest('.praktikant-card').classList.add('touch-dragging');
        
        // Prevent default to avoid scrolling
        event.preventDefault();
    }

    handleTouchMove(event) {
        if (!this.draggedRecordId) return;
        
        const touch = event.touches[0];
        this.touchCurrentX = touch.clientX;
        this.touchCurrentY = touch.clientY;
        this.isDragging = true;
        
        // Highlight drop zones
        const columns = this.template.querySelectorAll('.kanban-column');
        columns.forEach(column => {
            const rect = column.getBoundingClientRect();
            if (touch.clientX >= rect.left && touch.clientX <= rect.right &&
                touch.clientY >= rect.top && touch.clientY <= rect.bottom) {
                column.classList.add('touch-drag-over');
            } else {
                column.classList.remove('touch-drag-over');
            }
        });
        
        event.preventDefault();
    }

    handleTouchEnd(event) {
        if (!this.draggedRecordId) return;
        
        const touch = event.changedTouches[0];
        const elementBelow = document.elementFromPoint(touch.clientX, touch.clientY);
        const dropColumn = elementBelow ? elementBelow.closest('.kanban-column') : null;
        
        if (dropColumn) {
            const newStatus = dropColumn.dataset.status;
            const currentStatus = this.draggedRecord.AnwesendheitStatus__c;
            
            if (currentStatus !== newStatus) {
                this.processStatusChange(this.draggedRecordId, newStatus, currentStatus);
            }
        }
        
        // Clean up
        this.cleanupTouchDrag();
    }

    cleanupTouchDrag() {
        this.isDragging = false;
        this.draggedRecordId = null;
        this.draggedRecord = {};
        
        // Remove all visual feedback
        const cards = this.template.querySelectorAll('.praktikant-card');
        cards.forEach(card => card.classList.remove('touch-dragging'));
        
        const columns = this.template.querySelectorAll('.kanban-column');
        columns.forEach(column => column.classList.remove('touch-drag-over'));
    }

    // Status Change Processing
    processStatusChange(recordId, newStatus, currentStatus) {
        this.targetStatus = newStatus;
        
        // If moving to Entschuldigt, show reason modal
        if (newStatus === 'Entschuldigt') {
            this.showReasonModal = true;
            this.reasonText = '';
        } else {
            // Direct update for other status changes
            this.updateStatus(recordId, newStatus, '');
        }
    }

    // Modal Event Handlers
    handleReasonChange(event) {
        this.reasonText = event.target.value;
    }

    closeReasonModal() {
        this.showReasonModal = false;
        this.reasonText = '';
        this.draggedRecordId = null;
        this.targetStatus = '';
        this.cleanupTouchDrag();
    }

    confirmStatusChange() {
        if (this.reasonText.trim().length === 0) {
            this.showToast('Error', 'Please provide a reason for marking as Entschuldigt', 'error');
            return;
        }
        
        this.updateStatus(this.draggedRecordId, this.targetStatus, this.reasonText);
        this.closeReasonModal();
    }

    // Update Status Method
    async updateStatus(recordId, newStatus, reason) {
        this.isLoading = true;
        
        try {
            await updatePraktikantStatus({
                recordId: recordId,
                newStatus: newStatus,
                reason: reason
            });
            
            // Refresh the data
            await refreshApex(this.wiredPraktikantRecords);
            
            this.showToast('Success', `Status updated to ${newStatus}`, 'success');
        } catch (error) {
            console.error('Error updating status:', error);
            this.showToast('Error', 'Failed to update status: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
            this.cleanupTouchDrag();
        }
    }

    // Utility method to show toast messages
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    // Connected callback for initialization
    connectedCallback() {
        // Add global touch event listeners for better mobile support
        document.addEventListener('touchmove', this.preventDefaultTouch.bind(this), { passive: false });
    }

    disconnectedCallback() {
        // Clean up global event listeners
        document.removeEventListener('touchmove', this.preventDefaultTouch.bind(this));
    }

    preventDefaultTouch(event) {
        if (this.isDragging) {
            event.preventDefault();
        }
    }

    // Method to refresh data manually
    @api
    refreshData() {
        this.isLoading = true;
        return refreshApex(this.wiredPraktikantRecords)
            .then(() => {
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', 'Failed to refresh data', 'error');
            });
    }
}