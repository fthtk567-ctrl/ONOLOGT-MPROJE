// Firebase Cloud Messaging Service Worker
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBQwN-n2qxLIbOiyJn688LwuJteEd21rfE",
  authDomain: "onlog-push.firebaseapp.com",
  projectId: "onlog-push",
  storageBucket: "onlog-push.firebasestorage.app",
  messagingSenderId: "253730298253",
  appId: "1:253730298253:web:23fdb8667c67f9db1805c4"
});

const messaging = firebase.messaging();

// Background message handler
messaging.onBackgroundMessage((payload) => {
  console.log('Background message received:', payload);
  
  const notificationTitle = payload.notification?.title || 'ONLOG Bildirim';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
