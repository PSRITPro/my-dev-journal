const fetch = require('node-fetch');
const msal = require('@azure/msal-node');

// Set up MSAL configuration
const msalConfig = {
    auth: {
        clientId: 'YOUR_CLIENT_ID',
        authority: 'https://login.microsoftonline.com/YOUR_TENANT_ID',
        clientSecret: 'YOUR_CLIENT_SECRET',
    },
};

const cca = new msal.ConfidentialClientApplication(msalConfig);

const getAccessToken = async () => {
    const clientCredentialRequest = {
        scopes: ['https://graph.microsoft.com/.default'],
    };

    const response = await cca.acquireTokenByClientCredential(clientCredentialRequest);
    return response.accessToken;
};

const fetchViewedItems = async () => {
    const token = await getAccessToken();

    const response = await fetch('https://graph.microsoft.com/v1.0/me/insights/used', {
        method: 'GET',
        headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
        },
    });

    if (response.ok) {
        const data = await response.json();
        const viewedDocuments = data.value.filter(item => item.resourceVisualization && item.resourceVisualization.containerType === 'Drive');
        
        // Output the viewed documents
        console.log(viewedDocuments);
    } else {
        console.error('Error fetching insights:', response.statusText);
    }
};

// Call the function
fetchViewedItems();
