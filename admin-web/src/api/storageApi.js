import api from './axios';

// Cache SAS tokens by blob URL
const sasTokenCache = new Map();

// Generate SAS token for blob read
export const generateReadSasToken = async (blobUrl) => {
  try {
    // Check cache first
    if (sasTokenCache.has(blobUrl)) {
      const cached = sasTokenCache.get(blobUrl);
      // Check if token is still valid (expires in 5 minutes, cache for 4 minutes)
      if (cached.expiresAt > Date.now()) {
        return cached.signedUrl;
      }
      sasTokenCache.delete(blobUrl);
    }

    // Extract container and blob name from URL
    const url = new URL(blobUrl);
    const pathParts = url.pathname.split('/').filter(p => p);
    if (pathParts.length < 2) {
      throw new Error('Invalid blob URL');
    }
    
    const containerName = pathParts[0];
    const blobName = pathParts.slice(1).join('/');

    // Request SAS token from backend
    const response = await api.post('/storage/sas', {
      containerName,
      blobName,
      access: 'read',
      expiresInSeconds: 300 // 5 minutes
    });

    const { signedUrl } = response.data;
    
    // Cache the signed URL (expires in 4 minutes)
    sasTokenCache.set(blobUrl, {
      signedUrl,
      expiresAt: Date.now() + (4 * 60 * 1000)
    });

    return signedUrl;
  } catch (error) {
    console.error('Error generating SAS token:', error);
    return null;
  }
};

// Get avatar URL with SAS token
export const getAvatarWithSas = async (profilePictureUrl, fallbackName = 'User') => {
  if (!profilePictureUrl) {
    return `https://ui-avatars.com/api/?name=${encodeURIComponent(fallbackName)}&background=0D8ABC&color=fff`;
  }

  // If URL is from Azure Blob Storage, get SAS token
  if (profilePictureUrl.includes('.blob.core.windows.net')) {
    const signedUrl = await generateReadSasToken(profilePictureUrl);
    return signedUrl || `https://ui-avatars.com/api/?name=${encodeURIComponent(fallbackName)}&background=0D8ABC&color=fff`;
  }

  return profilePictureUrl;
};

// Preload avatar URLs with SAS tokens for a list of users
export const preloadAvatarsWithSas = async (users) => {
  const promises = users
    .filter(user => user?.profilePictureUrl?.includes('.blob.core.windows.net'))
    .map(user => generateReadSasToken(user.profilePictureUrl));
  
  await Promise.allSettled(promises);
};
