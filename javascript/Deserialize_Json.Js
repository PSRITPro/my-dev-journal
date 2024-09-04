document.addEventListener('DOMContentLoaded', () => {
    fetch('neos-t1452-eh-test-Json-quotes.json')
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok ' + response.statusText);
            }
            return response.text(); // Read as text to allow manual JSON manipulation
        })
        .then(jsonText => {
            const updatedJsonContent = processJsonContent(jsonText);
            const jsonData = JSON.parse(updatedJsonContent); // Convert back to JSON object
            generateTableHeaders(jsonData);
            populateTable(jsonData);
        })
        .catch(error => console.error('Error fetching the JSON data:', error));
});

function processJsonContent(jsonContent) {
    // Define a regex pattern to match JSON-like structures inside braces
    const pattern = /\{([^{}]*)\}/g;

    let match;
    let updatedContent = jsonContent;

    while ((match = pattern.exec(jsonContent)) !== null) {
        const contentInsideBraces = match[1];
        const splitContent = contentInsideBraces.split(/:(.+)/);

        splitContent.forEach(jContent => {
            const pattern2 = /^"(.*)"$/;
            const matchesJContent = jContent.trim().match(pattern2);

            if (matchesJContent) {
                const originalValue = matchesJContent[1];
                const escapedValue = originalValue.replace(/"/g, '\\"');

                // Update the content with escaped quotes
                updatedContent = updatedContent.replace(originalValue, escapedValue);
            }
        });
    }

    return updatedContent;
}

function generateTableHeaders(data) {
    const tableHead = document.querySelector('#data-table thead');
    
    // Clear existing table headers
    tableHead.innerHTML = '';

    if (data.length === 0) return;

    // Collect all unique headers
    let headers = new Set();
    data.forEach(item => {
        Object.keys(item).forEach(key => {
            if (key === 'columns') {
                item[key].forEach(column => {
                    Object.keys(column).forEach(colKey => headers.add(colKey));
                });
            } else {
                headers.add(key);
            }
        });
    });

    // Create table header row
    const headerRow = document.createElement('tr');
    headers.forEach(header => {
        const th = document.createElement('th');
        th.textContent = header;
        headerRow.appendChild(th);
    });
    tableHead.appendChild(headerRow);
}

function populateTable(data) {
    const tableBody = document.querySelector('#data-table tbody');
    
    // Clear existing table rows
    tableBody.innerHTML = '';

    data.forEach(item => {
        const row = document.createElement('tr');
        
        // Collect data for each cell
        const rowData = [];
        Object.keys(item).forEach(key => {
            if (key === 'columns') {
                item[key].forEach(column => {
                    Object.keys(column).forEach(colKey => {
                        const headerIndex = Array.from(document.querySelectorAll('#data-table thead th')).findIndex(th => th.textContent === colKey);
                        if (headerIndex !== -1) {
                            rowData[headerIndex] = column[colKey];
                        }
                    });
                });
            } else {
                const headerIndex = Array.from(document.querySelectorAll('#data-table thead th')).findIndex(th => th.textContent === key);
                if (headerIndex !== -1) {
                    rowData[headerIndex] = item[key];
                }
            }
        });

        // Create table cells with dynamic values
        rowData.forEach(data => {
            const td = document.createElement('td');
            td.textContent = data !== null && data !== undefined ? data : '';
            row.appendChild(td);
        });
        
        // Append row to table body
        tableBody.appendChild(row);
    });
}
