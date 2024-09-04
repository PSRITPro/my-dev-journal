// Handles UI updates
export function displayResult(valid, content) {
    const outputElement = document.getElementById('output');
    const copyButton = document.getElementById('copyButton');
    if (valid) {
        outputElement.textContent = 'Valid JSON:\n' + JSON.stringify(content, null, 2);
        copyButton.classList.remove('hidden');
    } else {
        outputElement.textContent = 'Error: Invalid JSON content.\n' + content;
        copyButton.classList.add('hidden');
    }
}
