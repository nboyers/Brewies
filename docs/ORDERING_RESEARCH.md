# Research: ordering through delivery platforms

**Question.** Could Brewies place orders on a user's behalf through a delivery platform such as DoorDash or Grubhub, take a fee, and send the order to the cafe or brewery?

**Short answer.** Not through the big delivery platforms. A real route exists only through each cafe's own point-of-sale system, and it is effectively a second business. Researched in November 2026; platform terms change, so recheck before acting.

## DoorDash

- The [Marketplace API](https://developer.doordash.com/en-US/docs/marketplace/overview/getting_started/requesting_access/) is **merchant-side and approval-only**. It lets approved merchants and their software providers manage menus and receive orders. Orders flow *from* DoorDash *to* the merchant.
- Access requests are reviewed on a quarterly basis, and the integration pipeline has been at capacity.
- The closest thing to ordering for a consumer is [DoorDash MCP](https://developer.doordash.com/en-US/docs/mcp/overview/about_mcp/), which lets an agent order for a signed-in consumer. It is aimed at corporate and organizational ordering, and is not available for consumer-facing products.

## Grubhub

- The [Partner Integration API](https://grubhub-developers.zendesk.com/hc/en-us) is gated. There is no self-serve key. Access runs through a review, a kickoff call and a pilot with real restaurants.
- Middleware companies (Deliverect, Otter, Chowly, Cuboh, Checkmate) hold the access and serve restaurants, not consumer apps.

## The route that exists: per-cafe opt-in

### Square

[Square](https://developer.squareup.com/docs/payments-api/take-payments-and-collect-fees) is common among independent cafes.

- The cafe authorizes your app through OAuth. Without that, you can do nothing on its behalf.
- You create the order in the cafe's account (`ORDERS_WRITE`), then take payment through Square's Payments API.
- Your fee is set on the payment (`app_fee_money`), not the order. It can be up to 90% of the payment and needs the `PAYMENTS_WRITE_ADDITIONAL_RECIPIENTS` permission.
- Using the Orders API with a non-Square payment provider carries an extra 1% fee, per a developer forum answer that was not confirmed in official documentation.
- In-app Apple Pay is supported by Square's In-App Payments SDK, but needs a physical device to test.
- Square's standard US processing rate is 2.9% plus 30 cents, paid by the seller.

### Toast

[Toast](https://doc.toasttab.com/doc/devguide/integrationDevProcess.html) allows third-party ordering through a formal partner program: acceptance, a signed agreement and certification. A restaurant adds a partner itself in Toast's admin. It is possible, but slow, and gated by Toast.

## Apple's rules

[App Review Guideline 3.1.3(e)](https://developer.apple.com/app-store/review/guidelines/) says physical goods and services consumed outside the app, which includes food, must use payment methods other than in-app purchase, such as Apple Pay or card entry. So the 30% Apple commission does not apply to food orders, but the app must handle payment itself.

## Legal and reputational risk

Placing orders at a cafe that never agreed to it is what got the large platforms in trouble. DoorDash [paid $18M to settle a Chicago suit](https://www.restaurantbusinessonline.com/technology/doordash-pay-18m-settle-chicago-lawsuit-alleging-deceptive-tactics) that alleged it listed restaurants without consent and misled customers about prices. Grubhub [paid $25M to settle with the FTC and Illinois](https://www.restaurantdive.com/news/grubhub-25-million-dollar-settlement-ftc/735814/). Any ordering feature should be **opt-in by the cafe**.

## What a real version would need

- A backend that stores each cafe's authorization securely
- A sign-up flow for cafes, since each one must connect to Brewies
- In-app payments with Apple Pay
- Menu and availability syncing
- Refunds, wrong orders and support
- A reason for a cafe to choose Brewies over its own ordering app

## Recommendation

Do not build this yet. Test demand cheaply first: an "Order ahead" button that opens a cafe's own ordering page where one exists, and see whether anyone taps it. That tells you whether people want ordering inside Brewies before taking on payments, a backend and cafe sales.
