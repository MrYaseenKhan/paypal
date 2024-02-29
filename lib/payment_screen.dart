import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:paypal_flutter/paypal_services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentScreen extends StatefulWidget {
  final Function(String?) onFinish;
  const PaymentScreen({super.key, required this.onFinish});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? checkoutUrl;
  String? executeUrl;
  String? accessToken;
  PaypalServices services = PaypalServices();
  WebViewController controller = WebViewController();

  // You may alter the default value to whatever you like.
  Map<dynamic, dynamic> defaultCurrency = {
    "symbol": "USD ",
    "decimalDigits": 2,
    "symbolBeforeTheNumber": true,
    "currency": "USD"
  };

  bool isEnableShipping = false;
  bool isEnableAddress = false;

  String returnURL = 'https://api.sandbox.paypal.com/payment/success';
  String cancelURL = 'https://api.sandbox.paypal.com/payment/cancel';

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      try {
        accessToken = await services.getAccessToken();
        log(".....................accessToken : $accessToken");

        final transactions = getOrderParams();
        final res =
        await services.createPaypalPayment(transactions, accessToken);
        if (res != null) {
          setState(() {
            checkoutUrl = res["approvalUrl"];
            executeUrl = res["executeUrl"];
            controller = WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..setBackgroundColor(const Color(0x00000000))
              ..setNavigationDelegate(
                NavigationDelegate(
                  onProgress: (int progress) {
                    // Update loading bar.
                  },
                  onPageStarted: (String url) {},
                  onPageFinished: (String url) {},
                  onWebResourceError: (WebResourceError error) {},
                  onNavigationRequest: (NavigationRequest request) {
                    if (request.url.contains(returnURL)) {
                      final uri = Uri.parse(request.url);
                      final payerID = uri.queryParameters['PayerID'];
                      log(".....................ID for Transaction........$executeUrl");
                      if (payerID != null) {
                        services
                            .executePayment(executeUrl, payerID, accessToken)
                            .then((id) {
                         log(".....................Payment Id : $id");
                          widget.onFinish(id);
                         // Navigator.of(context).pop();
                        });
                      } else {
                      //  Navigator.of(context).pop();
                      }
                    //  Navigator.of(context).pop();
                    }
                    if (request.url.contains(cancelURL)) {
                     // Navigator.of(context).pop();
                    }
                    return NavigationDecision.navigate;
                  },
                ),
              )
              ..loadRequest(Uri.parse('$checkoutUrl'));
          });
        }
      } catch (ex) {
        final snackBar = SnackBar(
          content: Text(ex.toString()),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'Close',
            onPressed: () {
              // Some code for undoing the alteration.
            },
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    });

  }

  // item name, price and quantity here
  String itemName = 'One plus 10';
  String itemPrice = '100';
  int quantity = 1;

  Map<String, dynamic> getOrderParams() {
    List<Map<String, dynamic>> items = [
      {
        "name": itemName,
        "quantity": quantity,
        "price": itemPrice, // Assuming itemPrice is a string representing the price
        "currency": defaultCurrency["currency"]
      }
    ];

    // Checkout Invoice Specifics
    String totalAmount = itemPrice; // Set total amount to match the item price
    String shippingCost = '0';
    int shippingDiscountCost = 0;
    String userFirstName = 'Yaseen';
    String userLastName = 'Khan';
    String addressCity = 'USA';
    String addressStreet = "i-10";
    String addressZipCode = '44000';
    String addressCountry = 'Pakistan';
    String addressState = 'Islamabad';
    String addressPhoneNumber = '4088172126';

    Map<String, dynamic> temp = {
      "intent": "sale",
      "payer": {"payment_method": "paypal"},
      "transactions": [
        {
          "amount": {
            "total": totalAmount,
            "currency": defaultCurrency["currency"],
            "details": {
              "shipping": shippingCost,
              "shipping_discount": ((-1.0) * shippingDiscountCost).toString()
            }
          },
          "description": "The payment transaction description.",
          "payment_options": {
            "allowed_payment_method": "INSTANT_FUNDING_SOURCE"
          },
          "item_list": {"items": items},
          if (isEnableShipping && isEnableAddress)
            "shipping_address": {
              "recipient_name": "$userFirstName $userLastName",
              "line1": addressStreet,
              "line2": "",
              "city": addressCity,
              "country_code": addressCountry,
              "postal_code": addressZipCode,
              "phone": addressPhoneNumber,
              "state": addressState
            },
        }
      ],
      "note_to_payer": "Contact us for any questions on your order.",
      "redirect_urls": {"return_url": returnURL, "cancel_url": cancelURL}
    };
    return temp;
  }


  @override
  Widget build(BuildContext context) {
    print(checkoutUrl);

    if (checkoutUrl != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.background,
          leading: GestureDetector(
            child: const Icon(Icons.arrow_back_ios),
            onTap: () => Navigator.pop(context),
          ),
        ),
        body: WebViewWidget(
          controller: controller,


        ),
      );
    } else {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              }),
          backgroundColor: Colors.black12,
          elevation: 0.0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
  }
}
