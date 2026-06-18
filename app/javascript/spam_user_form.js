// app/javascript/spam_user_form.js

export function setupFormInteractivity() {
  // Clear any existing listeners by handling it globally on the document
  // This ensures it survives Turbo page updates and form resets completely.

  // 1. Handle UID Auto-Populate on 'blur'
  document.removeEventListener('blur', handleUiBlur, true);
  document.addEventListener('blur', handleUiBlur, true);

  // 2. Handle Full Name Concatenation on 'input'
  document.removeEventListener('input', handleNameInput);
  document.addEventListener('input', handleNameInput);

  // 3. Handle Bootstrap Validation on 'submit'
  document.removeEventListener('submit', handleFormSubmit);
  document.addEventListener('submit', handleFormSubmit);
}

// --- Event Handler Functions ---

function handleUiBlur(event) {
  const target = event.target;
  // Match the email input field explicitly
  if (target && target.matches('input[name="ldap_record[mail]"]')) {
    const uidField = document.getElementById('username-field');
    if (uidField) {
      uidField.value = target.value;
    }
  }
}

function handleNameInput() {
  const givenNameInput = document.getElementById('ldap_record_givenName');
  const snInput = document.getElementById('ldap_record_sn');
  const fullNameInput = document.getElementById('ldap_record_fullName');

  // Only run if the name fields exist in the active DOM view
  if (givenNameInput && snInput && fullNameInput) {
    const firstName = givenNameInput.value.trim();
    const lastName = snInput.value.trim();

    if (firstName || lastName) {
      fullNameInput.value = `${firstName} ${lastName}`.trim();
    } else {
      fullNameInput.value = '';
    }
  }
}

function handleFormSubmit(event) {
  const form = event.target.closest('#ldap_record_form');
  if (form) {
    if (!form.checkValidity()) {
      event.preventDefault();
      event.stopPropagation();
    }
    form.classList.add('was-validated');
  }
}