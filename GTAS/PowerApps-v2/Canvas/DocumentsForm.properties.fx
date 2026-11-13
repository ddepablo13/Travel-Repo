// Insert an Edit form on Documents and name it DocumentsForm.
// Connect GTASDraftsV2, select only Attachments, then apply these properties.
// The SharePoint-generated Attachments card remains inside this form.

DataSource = GTASDraftsV2
Item = draft
DefaultMode = FormMode.Edit
X = 28
Y = 250
Width = 1090
Height = 350
OnSuccess =
    Set(draft,DocumentsForm.LastSubmit);
    Set(busy,false);
    Set(message,"Supporting documents saved.");
    Navigate(Expenses)
OnFailure =
    Set(busy,false);
    Set(message,Coalesce(DocumentsForm.Error,"Documents could not be saved. Retry before submitting."))

// Apply AccessibleLabel = "Supporting documents" to the generated Attachments control.
// Set MaxAttachments and MaxAttachmentSize to tenant policy, and reflect limits in card help text.
// ResetForm on the discard button discards unsaved file changes.
