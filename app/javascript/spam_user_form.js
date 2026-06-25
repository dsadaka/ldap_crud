// app/javascript/spam_user_form.js

// This code scrolls up when the user clicks edit
// document.addEventListener("turbo:click", function(event) {
//   // Check if the clicked element (or its parent) is an Edit link
//   const editLink = event.target.closest('a[href*="/edit"]');
//
//   if (editLink) {
//     // Find the topmost container of your index layout
//     const mainContainer = document.getElementById('main-spam-users-container');
//
//     if (mainContainer) {
//       // Smoothly scroll the window until the top of the container meets the viewport
//       mainContainer.scrollIntoView({
//         behavior: 'smooth',
//         block: 'start'
//       });
//     }
//   }
// });


// Shared state to track vertical placement between click and frame load
let lastClickedRowYOffset = 0;

document.addEventListener("turbo:click", function(event) {
  const editLink = event.target.closest('a[href*="/edit"]');
  const addLink = event.target.closest('a[href*="/new"]'); // Targets your Add User path

  if (editLink) {
    const clickedRow = editLink.closest('tr');
    if (clickedRow) {
      // Capture the row's midpoint position relative to the table container
      lastClickedRowYOffset = clickedRow.offsetTop + (clickedRow.offsetHeight / 2);
    }
  } else if (addLink) {
    // Reset to 0 so the form snaps cleanly back to the top of the workspace row
    lastClickedRowYOffset = 0;
  }
});

document.addEventListener("turbo:frame-load", function(event) {
  if (event.target.id === "record_form") {
    const formFrame = event.target;
    const columnWrapper = formFrame.closest('.col-md-5');
    const table = document.querySelector('table');
    const parentRow = columnWrapper ? columnWrapper.closest('.row') : null;

    if (!columnWrapper || !table || !parentRow) return;

    // Deterministic Mode Detection
    const hiddenMethodInput = formFrame.querySelector('input[name="_method"]');
    const isEditMode = hiddenMethodInput && ['patch', 'put'].includes(hiddenMethodInput.value.toLowerCase());

    if (!isEditMode) {
      lastClickedRowYOffset = 0;
    }

    parentRow.style.position = 'relative';
    columnWrapper.style.position = 'absolute';
    columnWrapper.style.right = '0';

    requestAnimationFrame(() => {
      const formHeight = columnWrapper.offsetHeight;

      if (!isEditMode || lastClickedRowYOffset === 0) {
        // --- ADD USER LOGIC ---
        columnWrapper.style.transition = "top 0.2s ease-out";
        columnWrapper.style.top = "0px";

        // Use a minimal timeout macro-task to let the browser frame render completely
        setTimeout(() => {
          const topAnchor = document.querySelector('[data-position-anchor="top"]');
          if (topAnchor) {
            topAnchor.scrollIntoView({ behavior: 'smooth', block: 'start' });
          }
        }, 10);

      } else {
        // --- EDIT USER LOGIC ---
        let targetTop = lastClickedRowYOffset - (formHeight / 2);

        const maxTop = table.offsetHeight - formHeight;
        if (targetTop > maxTop) targetTop = maxTop;
        if (targetTop < 0) targetTop = 0;

        columnWrapper.style.transition = "top 0.2s ease-out";
        columnWrapper.style.top = `${targetTop}px`;
      }

      // Auto-focus first input field
      const firstInput = formFrame.querySelector(
        'input:not([type="hidden"]):not([type="submit"]):not(:disabled), select:not(:disabled), textarea:not(:disabled)'
      );

      if (firstInput) {
        firstInput.focus();
        if (typeof firstInput.setSelectionRange === "function" && firstInput.value) {
          const length = firstInput.value.length;
          firstInput.setSelectionRange(length, length);
        }
      }
    });
  }
});

// Re-align the absolute column if a validation error expands the form height

document.addEventListener("turbo:submit-end", function(event) {
  const formFrame = document.getElementById('record_form');

  // 422 Unprocessable Entity means validation or directory update failed
  if (formFrame && event.detail.formSubmission.result.statusCode === 422) {
    const columnWrapper = formFrame.closest('.col-md-5');
    const table = document.querySelector('table');

    if (!columnWrapper || !table || lastClickedRowYOffset === 0) return;

    // Wait one rendering pass for the error block to expand the box footprint
    requestAnimationFrame(() => {
      const formHeight = columnWrapper.offsetHeight;
      let targetTop = lastClickedRowYOffset - (formHeight / 2);

      const maxTop = table.offsetHeight - formHeight;
      if (targetTop > maxTop) targetTop = maxTop;
      if (targetTop < 0) targetTop = 0;

      columnWrapper.style.transition = "top 0.2s ease-out";
      columnWrapper.style.top = `${targetTop}px`;
    });
  }
});

// app/assets/javascripts/spam_user_form.js

// Intercept native submit BEFORE Turbo can touch the event lifecycle
document.addEventListener("submit", function(event) {
  const form = event.target;

  // Target only your Bootstrap validation forms
  if (form.classList.contains('needs-validation')) {
    if (!form.checkValidity()) {
      // Completely halt the event right here in the browser layout
      event.preventDefault();
      event.stopPropagation();

      // Force Bootstrap to highlight the missing fields in red immediately
      form.classList.add('was-validated');
    }
  }
}, true); // The 'true' flag ensures we capture this event at the very start of the stack

// document.addEventListener("turbo:click", function(event) {
//   const editLink = event.target.closest('a[href*="/edit"]');
//
//   if (editLink) {
//     // Get the unique row ID from the data attribute
//     const rowId = editLink.getAttribute('data-row-id');
//     const clickedRow = document.getElementById(rowId);
//
//     if (clickedRow) {
//       // Calculate where the row sits relative to the viewable screen (viewport)
//       const rowPosition = clickedRow.getBoundingClientRect().top + window.scrollY;
//
//       // Smoothly slide the page so the clicked row is positioned comfortably near the top
//       window.scrollTo({
//         top: rowPosition - 120, // Subtracting 120px gives breathing room for your PristineEmail navbar
//         behavior: 'smooth'
//       });
//     }
//   }
// });
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
