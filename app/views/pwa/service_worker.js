// The listener must stay synchronous: Safari rejects waitUntil() calls made
// after an await, and iOS revokes push subscriptions when a push event ends
// without a visible notification.
self.addEventListener("push", (event) => {
  const data = event.data.json()
  event.waitUntil(Promise.all([ showNotification(data), updateBadgeCount(data.options) ]))
})

async function showNotification({ title, options }) {
  return self.registration.showNotification(title, options)
}

async function updateBadgeCount({ data } = {}) {
  return self.navigator.setAppBadge?.(data?.badge || 0)
}

self.addEventListener("notificationclick", (event) => {
  event.notification.close()

  const url = new URL(event.notification.data.path, self.location.origin).href
  event.waitUntil(openURL(url))
})

async function openURL(url) {
  const clients = await self.clients.matchAll({ type: "window" })
  const focused = clients.find((client) => client.focused)

  if (focused) {
    await focused.navigate(url)
  } else {
    await self.clients.openWindow(url)
  }
}
