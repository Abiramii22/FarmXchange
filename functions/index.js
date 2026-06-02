const crypto = require("crypto");
const admin = require("firebase-admin");
const functions = require("firebase-functions");
const Razorpay = require("razorpay");

admin.initializeApp();

const db = admin.firestore();

function razorpayClient() {
  const keyId = process.env.RAZORPAY_KEY_ID;
  const keySecret = process.env.RAZORPAY_KEY_SECRET;

  // âœ… TEMPORARY COMMENT FOR TESTING
  // if (!keyId || !keySecret) {
  //   throw new functions.https.HttpsError(
  //     "failed-precondition",
  //     "Razorpay keys are not configured"
  //   );
  // }

  return new Razorpay({
    key_id: keyId,
    key_secret: keySecret,
  });
}

function paiseFromRupees(value) {
  const amount = Number(value || 0);

  // âœ… TEMPORARY COMMENT FOR TESTING
  // if (!Number.isFinite(amount) || amount <= 0) {
  //   throw new functions.https.HttpsError(
  //     "invalid-argument",
  //     "Invalid payment amount"
  //   );
  // }

  return Math.round(amount * 100);
}

exports.createRazorpayOrder = functions.https.onCall(async (data) => {
  const bookingId = String(data.bookingId || "");

  // âœ… TEMPORARY COMMENT FOR TESTING
  // if (!bookingId) {
  //   throw new functions.https.HttpsError(
  //     "invalid-argument",
  //     "bookingId is required"
  //   );
  // }

  const bookingRef = db.collection("bookings").doc(bookingId);
  const bookingSnap = await bookingRef.get();

  // âœ… TEMPORARY COMMENT FOR TESTING
  // if (!bookingSnap.exists) {
  //   throw new functions.https.HttpsError("not-found", "Booking not found");
  // }

  const booking = bookingSnap.data() || {};
  const amountPaise = paiseFromRupees(booking.price || data.amount);

  const receipt = `booking_${bookingId}`.slice(0, 40);

  const order = await razorpayClient().orders.create({
    amount: amountPaise,
    currency: "INR",
    receipt,
    notes: {
      bookingId,
      userId: String(booking.userId || ""),
      machine: String(booking.machine || ""),
    },
  });

  await bookingRef.set(
    {
      paymentMethod: "Razorpay",
      paymentStatus: "Payment Started",
      razorpayOrderId: order.id,
      razorpayAmount: amountPaise,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return {
    keyId: process.env.RAZORPAY_KEY_ID,
    orderId: order.id,
    amount: order.amount,
    currency: order.currency,
  };
});

exports.verifyRazorpayPayment = functions.https.onCall(async (data) => {
  const bookingId = String(data.bookingId || "");
  const razorpayPaymentId = String(data.razorpayPaymentId || "");
  const razorpayOrderId = String(data.razorpayOrderId || "");
  const razorpaySignature = String(data.razorpaySignature || "");

  // âœ… TEMPORARY COMMENT FOR TESTING
  // if (!bookingId || !razorpayPaymentId || !razorpayOrderId || !razorpaySignature) {
  //   throw new functions.https.HttpsError(
  //     "invalid-argument",
  //     "Missing Razorpay verification fields"
  //   );
  // }

  const expectedSignature = crypto
    .createHmac("sha256", process.env.RAZORPAY_KEY_SECRET || "")
    .update(`${razorpayOrderId}|${razorpayPaymentId}`)
    .digest("hex");

  // âœ… TEMPORARY COMMENT FOR TESTING
  // if (expectedSignature !== razorpaySignature) {
  //   await db.collection("bookings").doc(bookingId).set(
  //     {
  //       paymentStatus: "Verification Failed",
  //       razorpaySignatureVerified: false,
  //       updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  //     },
  //     { merge: true }
  //   );

  //   throw new functions.https.HttpsError(
  //     "permission-denied",
  //     "Payment signature verification failed"
  //   );
  // }

  await db.collection("bookings").doc(bookingId).set(
    {
      paymentMethod: "Razorpay",
      paymentStatus: "Paid",
      razorpayPaymentId,
      razorpayOrderId,
      razorpaySignatureVerified: true,
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return {
    ok: true,
    paymentStatus: "Paid",
  };
});

exports.markRazorpayPaymentFailed = functions.https.onCall(async (data) => {
  const bookingId = String(data.bookingId || "");

  // âœ… TEMPORARY COMMENT FOR TESTING
  // if (!bookingId) {
  //   throw new functions.https.HttpsError(
  //     "invalid-argument",
  //     "bookingId is required"
  //   );
  // }

  await db.collection("bookings").doc(bookingId).set(
    {
      paymentMethod: "Razorpay",
      paymentStatus: "Failed",
      razorpayFailureCode: data.code || "",
      razorpayFailureMessage: data.message || "",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return { ok: true };
});


exports.requestRazorpayRefund = functions.https.onCall(async (data) => {
  const bookingId = String(data.bookingId || "");
  const amount = Number(data.amount || 0);
  const reason = String(data.reason || "User requested refund");

  if (!bookingId || !Number.isFinite(amount) || amount <= 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Valid bookingId and amount are required"
    );
  }

  const bookingRef = db.collection("bookings").doc(bookingId);
  const bookingSnap = await bookingRef.get();
  if (!bookingSnap.exists) {
    throw new functions.https.HttpsError("not-found", "Booking not found");
  }

  const booking = bookingSnap.data() || {};
  const paymentId = booking.razorpayPaymentId;
  if (!paymentId) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Razorpay payment id is missing"
    );
  }

  await bookingRef.set(
    {
      status: "Cancelled",
      refundStatus: "Processing",
      refundReason: reason,
      refundAmount: amount,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  const refund = await razorpayClient().payments.refund(paymentId, {
    amount: Math.round(amount * 100),
    notes: {
      bookingId,
      reason,
    },
  });

  await bookingRef.set(
    {
      refundStatus: "Processing",
      refundId: refund.id,
      refundAmount: Number(refund.amount || 0) / 100,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return { ok: true, refundId: refund.id, refundStatus: "Processing" };
});
exports.razorpayWebhook = functions.https.onRequest(async (req, res) => {
  const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;
  if (!webhookSecret) {
    res.status(500).send("Webhook secret is not configured");
    return;
  }

  const signature = req.get("x-razorpay-signature") || "";
  const expectedSignature = crypto
    .createHmac("sha256", webhookSecret)
    .update(req.rawBody)
    .digest("hex");

  if (signature !== expectedSignature) {
    res.status(401).send("Invalid signature");
    return;
  }

  const event = req.body || {};
  const payment = event.payload &&
    event.payload.payment &&
    event.payload.payment.entity;
  const refund = event.payload &&
    event.payload.refund &&
    event.payload.refund.entity;

  const paymentBookingId = payment && payment.notes && payment.notes.bookingId
    ? String(payment.notes.bookingId)
    : "";
  const refundBookingId = refund && refund.notes && refund.notes.bookingId
    ? String(refund.notes.bookingId)
    : paymentBookingId;

  if (paymentBookingId && event.event === "payment.captured") {
    await db.collection("bookings").doc(paymentBookingId).set(
      {
        paymentStatus: "Paid",
        refundStatus: "Not Requested",
        razorpayPaymentId: payment.id,
        razorpayOrderId: payment.order_id,
        webhookPaymentCaptured: true,
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }

  if (paymentBookingId && event.event === "payment.failed") {
    await db.collection("bookings").doc(paymentBookingId).set(
      {
        paymentStatus: "Failed",
        razorpayPaymentId: payment.id,
        webhookPaymentFailed: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }

  if (refundBookingId && event.event === "refund.processed") {
    await db.collection("bookings").doc(refundBookingId).set(
      {
        status: "Cancelled",
        paymentStatus: "Refunded",
        refundStatus: "Refunded",
        refundId: refund.id,
        refundAmount: Number(refund.amount || 0) / 100,
        refundedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }

  if (refundBookingId && event.event === "refund.failed") {
    await db.collection("bookings").doc(refundBookingId).set(
      {
        refundStatus: "Refund Failed",
        refundId: refund.id,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }

  res.status(200).send("ok");
});

exports.resetPasswordWithPhone = functions.https.onCall(async (data) => {
  const phoneRaw = String(data.phone || "");
  const emailRaw = String(data.email || "").trim().toLowerCase();
  const newPassword = String(data.newPassword || "");
  const allDigits = phoneRaw.replace(/[^0-9]/g, "");
  const last10 = allDigits.slice(-10);
  const with91 = last10 ? `91${last10}` : "";

  if (!last10 || !emailRaw || newPassword.length < 6) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Phone, registered email and 6+ character password are required"
    );
  }

  async function findUserDoc() {
    const ids = Array.from(new Set([allDigits, with91, last10].filter(Boolean)));
    for (const id of ids) {
      const snap = await db.collection("users").doc(id).get();
      if (snap.exists) return { ref: snap.ref, snap };
    }

    for (const id of ids) {
      const query = await db
        .collection("users")
        .where("phone", "==", id)
        .limit(1)
        .get();
      if (!query.empty) {
        const snap = query.docs[0];
        return { ref: snap.ref, snap };
      }
    }

    return null;
  }

  const found = await findUserDoc();
  if (!found) {
    throw new functions.https.HttpsError("not-found", "Account not found");
  }

  const userDoc = found.snap.data() || {};
  const registeredEmail = String(userDoc.authEmail || userDoc.email || "")
    .trim()
    .toLowerCase();

  if (registeredEmail !== emailRaw) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Phone and email do not match this account"
    );
  }

  const authUser = await admin.auth().getUserByEmail(registeredEmail);
  await admin.auth().updateUser(authUser.uid, { password: newPassword });

  await found.ref.set(
    {
      uid: authUser.uid,
      authEmail: registeredEmail,
      email: registeredEmail,
      passwordKey: newPassword,
      passwordUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  await db.collection("passwordResetLogs").add({
    phone: String(userDoc.phone || allDigits),
    email: registeredEmail,
    status: "Changed",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { ok: true };
});
exports.phonePasswordLogin = functions.https.onCall(async (data) => {
  const phoneRaw = String(data.phone || "");
  const password = String(data.password || "");
  const expectedRole = String(data.expectedRole || "").trim().toLowerCase();
  const allDigits = phoneRaw.replace(/[^0-9]/g, "");
  const last10 = allDigits.slice(-10);
  const with91 = last10 ? `91${last10}` : "";

  if (!last10 || !password) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Phone and password are required"
    );
  }

  async function findUserDoc() {
    const ids = Array.from(new Set([allDigits, with91, last10].filter(Boolean)));
    for (const id of ids) {
      const snap = await db.collection("users").doc(id).get();
      if (snap.exists) return { ref: snap.ref, snap };
    }

    for (const id of ids) {
      const query = await db
        .collection("users")
        .where("phone", "==", id)
        .limit(1)
        .get();
      if (!query.empty) {
        const snap = query.docs[0];
        return { ref: snap.ref, snap };
      }
    }
    return null;
  }

  const found = await findUserDoc();
  if (!found) {
    throw new functions.https.HttpsError("not-found", "Account not found");
  }

  const userDoc = found.snap.data() || {};
  const savedPassword = String(userDoc.passwordKey || "");
  if (savedPassword !== password) {
    throw new functions.https.HttpsError("permission-denied", "Wrong password");
  }

  const savedRole = String(userDoc.role || "User").trim().toLowerCase();
  if (expectedRole && expectedRole !== savedRole) {
    throw new functions.https.HttpsError("permission-denied", "Role mismatch");
  }

  const email = String(userDoc.authEmail || userDoc.email || "")
    .trim()
    .toLowerCase();
  let authUser;
  if (email) {
    try {
      authUser = await admin.auth().getUserByEmail(email);
    } catch (_) {
      authUser = await admin.auth().createUser({
        email,
        password,
        displayName: String(userDoc.name || "User"),
      });
    }
    await admin.auth().updateUser(authUser.uid, { password });
  } else if (userDoc.uid) {
    authUser = await admin.auth().getUser(String(userDoc.uid));
  } else {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Account email missing"
    );
  }

  await found.ref.set(
    {
      uid: authUser.uid,
      authEmail: email || authUser.email || "",
      email: email || authUser.email || "",
      lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  const freshSnap = await found.ref.get();
  const freshUser = freshSnap.data() || userDoc;
  const token = await admin.auth().createCustomToken(authUser.uid);
  return { token, user: freshUser };
});