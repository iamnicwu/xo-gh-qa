({
  /**
   * Get FRC values and potentials for case.
   *
   * @param component The component.
   * @param caseId The caseId.
   */
  getFRCs: function(component, caseId) {
    var getFeatureRequestCanceledForCase = component.get('c.getFeatureRequestCanceledForCase');

    getFeatureRequestCanceledForCase.setParams({
      caseId: caseId
    });

    getFeatureRequestCanceledForCase.setCallback(this, function(response){
      var state = response.getState();
      if (state === 'SUCCESS') {
        var result = response.getReturnValue();
        component.set('v.FRCs', result.frcs);
        component.set('v.statusOpts', result.options);
        component.set('v.hasFRCs', result.frcs.length !== 0);
      } else {
        console.log('Error in getFRCs', response.getError());
        //TODO: handle errors
      }
    });

    $A.enqueueAction(getFeatureRequestCanceledForCase);
  },

  /**
   * Save the updated FRC list.
   *
   * @param component The component.
   * @param location The next location to navigate on success.
   */
  persistFRCs: function(component, location) {
    var caseId = component.get('v.caseId'),
      FRCs = component.get('v.FRCs').filter(function(frc) {
        return frc.isAdded;
      }),
      saveFRCsAction = component.get('c.updateFRCs'),
      frcObjects = [],
      defaultStatus = component.get('v.statusOpts')[0].value;

    FRCs.forEach(function(frc) {
      var obj = {
        SubProductChargeNumber: frc.SubProductChargeNumber,
        spcId: frc.spcId,
        Status: frc.Status || defaultStatus
      };

      if (frc.frcId) {
        obj.frcId = frc.frcId;
      }
      frcObjects.push(obj);
    });

    saveFRCsAction.setParams({
      caseId: caseId,
      addedFRCsString: JSON.stringify(frcObjects)
    });


    saveFRCsAction.setCallback(this, function(response) {
      var state = response.getState(),
        frcEvent = component.getEvent("FeatureRequestCanceledEvent");

      if (state === 'SUCCESS') {
        frcEvent.setParams({
          'success' : true,
          'location': location
        });
        frcEvent.fire();
      } else {
        console.log('Error in updateFRCs', response.getError());
        frcEvent.setParams({"success" : false});
        frcEvent.fire();
      }
    });

    $A.enqueueAction(saveFRCsAction);
  }
})