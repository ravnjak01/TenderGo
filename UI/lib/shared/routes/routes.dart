  import 'package:flutter/material.dart';
  class AppRoutes{

    static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    static const String splash = '/splash';
    static const String login = '/login';
    static const String registration = '/registration';
    static const String forgotPassword = '/forgot-password';
    static const String resetPassword = '/reset-password';
    static const String home = '/home';
    static const String tenderList = '/tenders';
    static const String tenderPost = '/tender-post';
    static const String tenderDetails = '/tender-details';
    static const String userProfile = '/user-profile';
    static const String editProfile = '/edit-profile';
    static const String myTenders = '/my-tenders';
    static const String myBids = '/my-bids';
    static const String admin = '/admin';
    static const String userPublicProfile = '/user-public-profile';
    static const String rateUser = '/rate-user';
    static const String recommendations = '/recommendations';
    static const String notifications = '/notifications';
    static const String pdfViewer = '/pdf-viewer';
  }