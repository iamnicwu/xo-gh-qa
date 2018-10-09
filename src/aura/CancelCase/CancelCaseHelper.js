({
  CANCELLED: 'cancelled',
  FILE_CHUNK_SIZE: 950000,
  MAX_FILE_SIZE: 4350000,
  SAVED: 'saved',
  CASE_ORIGIN_VALUES: [
    '', // Needed for default option
    'email',
    'phone'
  ],
  CASE_REASON_VALUES: [
    '', // Needed for default option
    'roi',
    'can\'t afford',
    'oob/no longer doing weddings',
    'no longer doing weddings',
    'review disputes',
    'other'
  ],
  OUTCOME_VALUES: [
    '', // Needed for default option
    'cancelled',
    'saved',
    'saved hard concessions',
    'saved no concessions',
    'saved soft concessions',
    'partial save'
  ],
  SAVED_BY_VALUES: [
    '',
    'reset expectations',
    'downsell/remove upgrades',
    'offering non-rnewal as an alternative',
    'free product upgrade',
    'rate freeze',
    'other'
  ],
  TYPE_VALUES: [
    '', // Needed for default option
    'cancel request',
    'non-renewal request'
  ],
  /**
   * Used to initalize the component. Retrieve relevant data
   *
   * @param component - The CancelCase component.
   */
  init: function(component) {
    var self = this;
    component.set('v.retrievingCase', true);

    this.getAllOptions(component)
      .then($A.getCallback(function() {
        self.getCase(component);
      }))
      .then($A.getCallback(function() {
        self.savedByDisabled(component);
        component.set('v.retrievingCase', false);
      }))
      .catch($A.getCallback(function() {
        component.set('v.retrievingCase', false);
      }));
  },

  /**
   * Handler for going to previous page.
   * @param component - The CancelCase component.
   */
  previous: function(component) {
    var currentPage = component.get('v.currentPage');
    component.set('v.currentPage', --currentPage);
  },

  /**
   * Handler for going to next page.
   * @param component - The CancelCase component.
   */
  next: function(component) {
    var currentPage = component.get('v.currentPage');
    component.set('v.currentPage', ++currentPage);
  },

  /**
   * Handler for determining if the saved by select is disabled.
   * @param component - The CancelCase component.
   * @returns Boolean - Flag if saved by us disabled or not.
   */
  savedByDisabled: function(component) {
    var currentCase = component.get('v.currentCase'),
      outcome = currentCase.outcome || '',
      isDisabled = (outcome.toLowerCase().indexOf(this.SAVED) === -1);

    component.set('v.savedByDisabled', isDisabled);

    return isDisabled;
  },

  /**
   * Toggle the input for file uploads.
   * @param component - The CancelCase component.
   */
  toggleUploadInput: function(component) {
    var currentCase = component.get('v.currentCase'),
      outcome = currentCase.outcome || '',
      showUpload = (outcome.toLowerCase().indexOf(this.CANCELLED) > -1);

    component.set('v.showUploadInput', showUpload);
  },

  /**
   * Handler for navigating back to account object.
   * @param component - The CancelCase component.
   */
  navigateToAccount: function(component) {
    var accountId = component.get('v.recordId');

    $A.get('e.force:navigateToSObject')
      .setParams({
        recordId: accountId
      })
      .fire();
  },

  /**
   * Helper function to set the value from the change modal
   *
   * @param component - The CancelCase component.
   * @param event - The setModalValue event that was fired.
   */
  setValueFromModal: function(component, event) {
    var params = event.getParams(),
      resultItem = params.item,
      objectType = params.objectType,
      currentCase = component.get('v.currentCase');

    if (objectType === 'Account') {
      currentCase.accountId = resultItem.id;
      currentCase.accountName = resultItem.resultName;
    } else if (objectType === 'Contact') {
      currentCase.contactId = resultItem.id;
      currentCase.contactName = resultItem.resultName;
    } else if (objectType === 'User') {
      currentCase.caseOwnerId = resultItem.id;
      currentCase.caseOwnerName = resultItem.resultName;
    } else if (objectType === 'Task') {
      currentCase.associatedTaskOrEmail = resultItem.id;
      currentCase.associatedTaskOrEmailName = resultItem.resultName;
    }

    component.set('v.currentCase', currentCase);
  },

  /**
   * Retrieve origin values from backend
   *
   * @param component - The CancelCase component.
   */
  getAllOptions: function(component) {
    var self = this;

    return new Promise(function(resolve, reject) {
      var action = component.get('c.getAllPicklistOptions');

      action.setCallback(this, function(response){
        var state = response.getState(),
          allOptions;
        if (state === 'SUCCESS') {
          allOptions = response.getReturnValue();
          component.set('v.originOpts', allOptions.originOptions.filter(function(item) {
            return self.CASE_ORIGIN_VALUES.indexOf(item.value.toLowerCase()) > -1;
          }));
          component.set('v.typeOpts', allOptions.typeOptions.filter(function(item) {
            return self.TYPE_VALUES.indexOf(item.value.toLowerCase()) > -1;
          }));
          component.set('v.reasonOpts', allOptions.reasonOptions.filter(function(item) {
            return self.CASE_REASON_VALUES.indexOf(item.value.toLowerCase()) > -1;
          }));
          component.set('v.outcomeOpts', allOptions.outcomeOptions.filter(function(item) {
            return self.OUTCOME_VALUES.indexOf(item.value.toLowerCase()) > -1;
          }));
          component.set('v.savedByOpts', allOptions.savedByOptions.filter(function(item) {
            return self.SAVED_BY_VALUES.indexOf(item.value.toLowerCase()) > -1;
          }));
          resolve();
        } else {
          console.log('Error getAllOptions', response.getError());
          reject(response.getError());
        }
      });

      $A.enqueueAction(action);
    });
  },

  /**
   * Handler for handling file change
   *
   * @param component - The CancelCase component.
   * @param event - The CancelCase event.
   */
  handleFileChange: function(component, event) {
    var selectedFiles = event.getParam('files'),
      files = component.get('v.files');

    // only allow 1 file
    if (selectedFiles.length > 0) {
      files = [selectedFiles[0]]
    }

    component.set('v.files', files);
  },

  /**
   * Handler for removing a file from the list.
   * @param component - The CancelCase component.
   * @param event - The CancelCase event.
   */
  removeFile: function(component, event) {
    // the name of the button is equal to the index of the item in the list.
    var itemIdx = event.getSource().get('v.name'),
      files = component.get('v.files');

    files.splice(itemIdx, 1);
    component.set('v.files', files);
  },

  /**
   * Handler saving files in list.
   * @param component - The CancelCase component.
   */
  saveFiles: function(component) {
    var files = component.get('v.files'),
      currentCase = component.get('v.currentCase'),
      deleteAttachmentPromise = Promise.resolve(),
      self = this,
      promises = [];

    if (currentCase.attachments.length > 0 && currentCase.attachments[0].id) {
      deleteAttachmentPromise = self.deleteAttachment(component);
    }

    files.forEach(function(file, idx, filesList) {
      if (!file.isUploaded) {
        promises.push(new Promise(function (resolve, reject) {
            var fr = new FileReader();

            if (file.size > self.MAX_FILE_SIZE) {
              reject(new Error('File too big'));
              return;
            }

            fr.onload = function () {
              var fileContents = fr.result,
                base64Mark = 'base64,',
                dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;

              fileContents = fileContents.substring(dataStart);

              resolve(fileContents);
            };

            fr.readAsDataURL(file);
          })
          .then($A.getCallback(function(fileContents) {
            file.isUploading = true;
            filesList[idx] = file;
            component.set('v.files', filesList);
            return self.uploadFile(component, file, fileContents)
          }))
          .then($A.getCallback(function() {
            file.isUploading = false;
            file.isUploaded = true;
            filesList[idx] = file;
            component.set('v.files', filesList);
          }))
        );
      }
    });

    return deleteAttachmentPromise
      .then($A.getCallback(function() {
        return Promise.all(promises);
      }))
      .then($A.getCallback(function() {
        console.log('ALL FILES UPLOADED');
      }))
      .catch($A.getCallback(function(err) {
        if (err.message === 'File too big') {
          alert('File exceeds the max size of 4.3 MB');
        }
        console.log('Error uploading files', err);
        return Promise.reject(err);
      }));
  },

  /**
   * Handler to upload a file to Salesforce.
   * @param component - The CancelCase component.
   * @param file - The file object.
   * @param fileContents - The file contents.
   */
  uploadFile: function(component, file, fileContents) {
    var fromPos = 0;
    var toPos = Math.min(fileContents.length, fromPos + this.FILE_CHUNK_SIZE);

    return this.uploadChunk(component, file, fileContents, fromPos, toPos, '');
  },

  /**
   * Handler to upload a chunk of the file.
   * @param component - The CancelCase component.
   * @param file - The file object.
   * @param fileContents - The file contents.
   * @param fromPos - The from position.
   * @param toPos - The to position.
   * @param attachId - The attachment Id. Needed to append content to existing file
   */
  uploadChunk: function(component, file, fileContents, fromPos, toPos, attachId) {
    var action = component.get('c.saveFileChunk'),
      chunk = fileContents.substring(fromPos, toPos),
      currentCase = component.get('v.currentCase'),
      self = this;

    return new Promise(function(resolve, reject) {
      action.setParams({
          parentId: currentCase.id,
          fileName: file.name,
          base64Data: encodeURIComponent(chunk),
          contentType: file.type,
          attachmentId: attachId
        });

        action.setCallback(this, function(response) {
          var state = response.getState();

          if (state === 'SUCCESS') {
            var attachId = response.getReturnValue();

            fromPos = toPos;
            toPos = Math.min(fileContents.length, fromPos + self.FILE_CHUNK_SIZE);

            if (fromPos < toPos) {
              resolve([true, attachId]);
            } else {
              resolve(false);
            }
          } else {
            console.log('Error uploadChunk ' + file.name, response.getError());
            reject(response.getError());
          }
        });

        console.log('uploading chunk from ' + fromPos + ' to ' + toPos);
        $A.enqueueAction(action);
      })
      .then($A.getCallback(function(result) {
        var shouldUploadNextChunk = result[0],
          attachId = result[1];

        if (shouldUploadNextChunk && attachId) {
          return self.uploadChunk(component, file, fileContents, fromPos, toPos, attachId);
        }
      }));
  },

  /**
   * Handler to delete an attacment.
   * @param component - The CancelCase component.
   */
  deleteAttachment: function(component) {
    var action = component.get('c.removeAttachment'),
      currentCase = component.get('v.currentCase');

    return new Promise(function(resolve, reject) {
      action.setParams({
        attachmentId: currentCase.attachments[0].id
      });

      action.setCallback(this, function(response) {
        var state = response.getState();

        if (state === 'SUCCESS') {
          resolve();
        } else {
          console.log('Error deleteAttachment',response.getError());
          reject();
        }
      });

      $A.enqueueAction(action);
    });
  },

  /**
   * Retrieve the case from backend
   *
   * @param component - The CancelCase component.
   */
  getCase: function(component) {
    return new Promise(function(resolve, reject) {
      var accountId = component.get('v.recordId'),
        action = component.get('c.getCaseForAccount');

      action.setParams({
        accountId: accountId
      });

      action.setCallback(this, function(response){
        var state = response.getState();

        if (state === 'SUCCESS') {
          component.set('v.currentCase', response.getReturnValue());
          resolve();
        } else {
          console.log('Error getCase', response.getError());
          reject(response.getError());
        }
      });

      $A.enqueueAction(action);
    });
  },

  /**
   * Save the case object
   *
   * @param component - The CancelCase component.
   * @param goNext - Flag to go to next page.
   * @param insertOpp - If true set param for creating cancel opportunity.
   */
  saveCase: function(component, goNext, insertOpp) {
    var self = this,
      currentPage = component.get('v.currentPage'),
      files = component.get('v.files'),
      uploadFilePromise = Promise.resolve(),
      frcTable;

    if (currentPage === 3 && files.length > 0) {
      component.set('v.saving', true);
      uploadFilePromise = self.saveFiles(component);
    } else if (currentPage === 2) {
      // For a save action on page 2 we just need to trigger the save on the frcTable component and the navigation will be
      // handled on a event from that component.
      component.set('v.saving', true);
      frcTable = component.find('frcTable');
      if (goNext) {
        frcTable.set('v.submitAndNext', true);
      } else {
        frcTable.set('v.submitAndAccount', true);
      }
      return;
    }

    return uploadFilePromise
      .then($A.getCallback(function() {
        return new Promise(function(resolve, reject) {
          var currentCase = component.get('v.currentCase'),
            action = component.get('c.saveCase'),
            originalRequestDate = currentCase.originalRequestDate || new Date(),
            // The specified string should use the standard date format “yyyy-MM-dd HH:mm:ss” in the local time zone
            dateStr = $A.localizationService.formatDate(originalRequestDate, 'yyyy-MM-dd HH:mm:ss');

          component.set('v.saving', true);

          currentCase.originalRequestDate = dateStr;

          if (self.savedByDisabled(component)) {
            currentCase.savedBy = null;
          }

          action.setParams({
            caseValues: currentCase,
            insertOpportunity: !!insertOpp
          });

          action.setCallback(this, function(response){
            var state = response.getState();
            component.set('v.saving', false);

            if (state === 'SUCCESS') {
              resolve();
            } else {
              console.log('Error saveCase', response.getError());
              reject(response.getError());
            }
          });

          $A.enqueueAction(action);
        });
      }))
      .then($A.getCallback(function() {
        // need to get case after a save to make sure we have up to date data,
        // including an id
        return self.getCase(component);
      }))
      .then($A.getCallback(function() {
        if (goNext) {
          self.next(component);
        } else {
          self.navigateToAccount(component);
        }
      }), function(err) {
        console.log(err, 'There was an error encountered attempting to save the case.');
      });
  }
})