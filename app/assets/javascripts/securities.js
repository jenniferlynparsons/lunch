$(function() {
  var $form = $('.manage-securities-form');
  var $checkboxes = $form.find('input[type=checkbox]');
  var $submitButton = $form.find('input[type=submit]');
  $checkboxes.on('change', function(e){
    // if boxes checked and all values are the same, enable submit
    var status = false;
    $form.find('input[type=checkbox]:checked').each(function(){
      var thisStatus = $(this).data('status');
      if (!status) {
        status = thisStatus;
      }
      else if (thisStatus != status) {
        status = false;
        return false;
      };
    });
    if (status) {
      $submitButton.attr('disabled', false);
    } else {
      $submitButton.attr('disabled', true);
    };
  });

  // Value of data attribute used in CSS to show/hide appropriate 'delivery-instructions-field'
  $('select[name=securities_release_delivery_instructions]').on('change', function(){
    $('.securities-delivery-instructions-fields').attr('data-selected-delivery-instruction', $(this).val());
  });

  // Confirm deletion of release
  $('.delete-release-trigger').on('click', function(e) {
    confirmReleaseDeletion();
  });

  function confirmReleaseDeletion() {
    $('body').flyout({
      topContent: $('.delete-release-flyout').clone(true),
      hideCloseButton: true
    });
    $('.flyout').addClass('flyout-confirmation-dialogue');
  };

  // Toggle Edit Securities Instructions
  $('.securities-download').on('click', function(){
    $('.securities-download-instructions').toggle();
  });

});