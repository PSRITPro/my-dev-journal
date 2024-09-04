import { readFile } from './Json_fileHandler.js';
import { validateAndProcessJsonContent } from './Json_Validator.js';
import { displayResult } from './Json_uiHandler.js';

document.addEventListener('DOMContentLoaded', () => {
    const fileInput = document.getElementById('fileInput');
    const validateButton = document.getElementById('validateButton');
    const copyButton = document.getElementById('copyButton');

    if (fileInput) {
        fileInput.addEventListener('change', handleFileSelect, false);
    } else {
        console.error('Element with id "fileInput" not found.');
    }

    if (validateButton) {
        validateButton.addEventListener('click', handleTextAreaValidation, false);
    } else {
        console.error('Element with id "validateButton" not found.');
    }

    if (copyButton) {
        copyButton.addEventListener('click', copyToClipboard, false);
    } else {
        console.error('Element with id "copyButton" not found.');
    }
});

function handleFileSelect(event) {
    const file = event.target.files[0];
    if (!file) {
        return;
    }
    readFile(file)
        .then(jsonText => {
            const { valid, content } = validateAndProcessJsonContent(jsonText);
            displayResult(valid, content);
        })
        .catch(error => {
            console.error('File reading error:', error);
            displayResult(false, 'Error reading file.');
        });
}

function handleTextAreaValidation() {
    const jsonText = document.getElementById('jsonInput').value;
    const { valid, content } = validateAndProcessJsonContent(jsonText);
    displayResult(valid, content);
}

function copyToClipboard() {
    const outputElement = document.getElementById('output');
    if (outputElement) {
        const text = outputElement.textContent;
        navigator.clipboard.writeText(text).then(() => {
            alert('JSON copied to clipboard!');
        }).catch(err => {
            console.error('Failed to copy text: ', err);
        });
    }
}
