const { onRequest } = require("firebase-functions/v2/https");

exports.chat = onRequest(async (req, res) => {

  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "*");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  try {
    const response = await fetch(
      "https://api.bytez.com/v1/chat/completions",
      {
        method: "POST",
        headers: {
          "Authorization": "Bearer 171fff1390fd31aed2ba068be26139f0",
          "Content-Type": "application/json"
        },
        body: JSON.stringify(req.body)
      }
    );

    const data = await response.json();

    res.json(data);

  } catch (e) {

    res.status(500).json({
      error: e.toString()
    });

  }

});