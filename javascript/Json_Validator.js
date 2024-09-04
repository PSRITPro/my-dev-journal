// Validates JSON content and attempts to correct it if needed
export function validateAndProcessJsonContent(jsonContent) {
    // Helper function to process JSON content and fix common issues
    function processJsonContent(content) {
        // Define a regex pattern to match JSON-like structures inside braces
        const pattern = /\{([^{}]*)\}/g;
    
        let match;
        let updatedContent = content;
    
        while ((match = pattern.exec(content)) !== null) {
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
    
    try {
        // Try to parse the JSON to check for validity
        const parsedContent = JSON.parse(jsonContent);
        return { valid: true, content: parsedContent };
    } catch (e) {
        console.error('JSON parsing error:', e.message);

        // Attempt to correct the JSON content
        const correctedContent = processJsonContent(jsonContent);
        
        // Try parsing again after correction
        try {
            const parsedContent = JSON.parse(correctedContent);
            return { valid: true, content: parsedContent };
        } catch (e) {
            return { valid: false, content: correctedContent };
        }
    }
}
