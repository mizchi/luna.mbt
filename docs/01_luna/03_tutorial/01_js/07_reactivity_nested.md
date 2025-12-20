---
title: "Reactivity: Nested Effects"
---

# Nested Effects

Effects can be nested to create scoped reactive contexts.

## Effect Ownership

When you create an effect inside another effect, the inner effect becomes "owned" by the outer one:

```typescript
const [showPanel, setShowPanel] = createSignal(false);
const [count, setCount] = createSignal(0);

createEffect(() => {
  if (showPanel()) {
    console.log("Panel shown");

    // This effect only exists while showPanel is true
    createEffect(() => {
      console.log("Count:", count());
    });
  }
});

setShowPanel(true);   // "Panel shown", "Count: 0"
setCount(1);          // "Count: 1"
setShowPanel(false);  // "Panel shown" (inner effect is disposed)
setCount(2);          // Nothing (inner effect no longer exists)
```

## Automatic Cleanup

When an outer effect re-runs, all inner effects are automatically disposed:

```typescript
const [page, setPage] = createSignal("home");
const [data, setData] = createSignal(null);

createEffect(() => {
  const currentPage = page();
  console.log("Loading page:", currentPage);

  // This effect is disposed when page changes
  createEffect(() => {
    console.log("Data updated:", data());
  });
});

setData({ title: "Home" });  // "Data updated: {title: Home}"
setPage("about");            // "Loading page: about" (inner effect disposed)
setData({ title: "About" }); // "Data updated: {title: About}" (new inner effect)
```

## Use Cases

### Conditional Subscriptions

```typescript
const [isLoggedIn, setIsLoggedIn] = createSignal(false);
const [notifications, setNotifications] = createSignal([]);

createEffect(() => {
  if (isLoggedIn()) {
    // Only subscribe to notifications when logged in
    createEffect(() => {
      const notifs = notifications();
      updateNotificationBadge(notifs.length);
    });
  }
});
```

### Scoped Resources

```typescript
const [selectedUser, setSelectedUser] = createSignal(null);

createEffect(() => {
  const user = selectedUser();
  if (!user) return;

  // WebSocket connection scoped to selected user
  const ws = new WebSocket(`/ws/user/${user.id}`);

  // Inner effect for messages
  createEffect(() => {
    ws.onmessage = (e) => {
      handleMessage(JSON.parse(e.data));
    };
  });

  onCleanup(() => {
    ws.close();
  });
});
```

### Dynamic Effect Chains

```typescript
const [tabs, setTabs] = createSignal(["home", "profile"]);

createEffect(() => {
  // Create an effect for each tab
  tabs().forEach(tab => {
    createEffect(() => {
      console.log(`Tab ${tab} is active:`, activeTab() === tab);
    });
  });
});

// When tabs change, old effects are disposed, new ones created
setTabs(["home", "settings", "profile"]);
```

## Owner Context

Effects track their "owner" - the context that created them:

```typescript
import { getOwner, runWithOwner } from '@mizchi/luna';

const [count, setCount] = createSignal(0);

createEffect(() => {
  const owner = getOwner();

  // Later, run code in this owner's context
  setTimeout(() => {
    runWithOwner(owner, () => {
      // This effect is owned by the original effect
      createEffect(() => {
        console.log("Delayed effect:", count());
      });
    });
  }, 1000);
});
```

## Memo Ownership

Memos also participate in ownership:

```typescript
createEffect(() => {
  // This memo is owned by the effect
  const doubled = createMemo(() => count() * 2);

  console.log("Doubled:", doubled());
});

// When effect re-runs, memo is recreated
```

## Common Patterns

### Conditional Feature Flags

```typescript
const [features, setFeatures] = createSignal({ analytics: false });

createEffect(() => {
  if (features().analytics) {
    // Analytics tracking only when enabled
    createEffect(() => {
      trackPageView(currentPage());
    });
  }
});
```

### Tab Content

```typescript
const [activeTab, setActiveTab] = createSignal("overview");

createEffect(() => {
  const tab = activeTab();

  // Each tab has its own reactive context
  if (tab === "overview") {
    createEffect(() => loadOverviewData());
  } else if (tab === "details") {
    createEffect(() => loadDetailsData());
  } else if (tab === "comments") {
    createEffect(() => loadCommentsData());
  }
});
```

## Caution: Memory Leaks

Be careful with effects created outside reactive contexts:

```typescript
// Wrong: effect never cleaned up
document.addEventListener("click", () => {
  createEffect(() => {
    console.log(count());  // Memory leak!
  });
});

// Correct: manage lifecycle
let dispose;
document.addEventListener("click", () => {
  dispose?.();  // Clean up previous
  dispose = createEffect(() => {
    console.log(count());
  });
});
```

## Try It

Create a "tabs" component where each tab has its own counter that's only tracked while that tab is active:

<details>
<summary>Solution</summary>

```typescript
const [activeTab, setActiveTab] = createSignal("a");
const [countA, setCountA] = createSignal(0);
const [countB, setCountB] = createSignal(0);

createEffect(() => {
  const tab = activeTab();
  console.log("Switched to tab:", tab);

  if (tab === "a") {
    createEffect(() => {
      console.log("Tab A count:", countA());
    });
  } else {
    createEffect(() => {
      console.log("Tab B count:", countB());
    });
  }
});

// Only logs for the active tab
setCountA(1);  // "Tab A count: 1" (if tab A is active)
setActiveTab("b");  // "Switched to tab: b"
setCountA(2);  // Nothing (tab A effect disposed)
setCountB(1);  // "Tab B count: 1"
```

</details>

## Next

Learn about [Show (Conditional Rendering) →](./flow_show)
