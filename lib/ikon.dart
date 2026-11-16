import 'package:flutter/widgets.dart';
// ignore_for_file: constant_identifier_names

/// Ikon aplikasi: set Lucide (garis tipis, bersih, tegas),
/// menggantikan Phosphor sejak v0.14.0 atas pilihan Adnan.
/// Sebelumnya: Material (≤0.12.1) lalu Phosphor (0.13.0).
///
/// Nama field SENGAJA meniru nama ikon Material lama supaya
/// seluruh tempat pemakaian cukup memakai awalan `Ikon.`
/// apa adanya. Lucide hanya punya SATU gaya (garis) — tidak
/// ada varian isi; keadaan terpilih dibedakan oleh warna dan
/// garis penanda, bukan bentuk ikon.
/// Berkas huruf di assets/fonts (dari paket lucide_icons,
/// font resmi Lucide); build release memangkasnya otomatis
/// ke ikon yang benar-benar dipakai.
class Ikon {
  Ikon._();

  static const IconData account_balance_outlined = IconData(0xf380, fontFamily: 'Lucide'); // landmark
  static const IconData account_balance_wallet_outlined = IconData(0xf588, fontFamily: 'Lucide'); // wallet
  static const IconData account_balance_wallet_rounded = IconData(0xf588, fontFamily: 'Lucide'); // wallet
  static const IconData add = IconData(0xf45e, fontFamily: 'Lucide'); // plus
  static const IconData add_box_outlined = IconData(0xf460, fontFamily: 'Lucide'); // plusSquare
  static const IconData add_business_outlined = IconData(0xf509, fontFamily: 'Lucide'); // store
  static const IconData add_rounded = IconData(0xf45e, fontFamily: 'Lucide'); // plus
  static const IconData arrow_back = IconData(0xf14f, fontFamily: 'Lucide'); // arrowLeft
  static const IconData arrow_downward_outlined = IconData(0xf13c, fontFamily: 'Lucide'); // arrowDown
  static const IconData arrow_upward_outlined = IconData(0xf15b, fontFamily: 'Lucide'); // arrowUp
  static const IconData backspace_outlined = IconData(0xf26e, fontFamily: 'Lucide'); // delete
  static const IconData bakery_dining = IconData(0xf265, fontFamily: 'Lucide'); // croissant
  static const IconData balance_outlined = IconData(0xf49f, fontFamily: 'Lucide'); // scale
  static const IconData bar_chart = IconData(0xf187, fontFamily: 'Lucide'); // barChart3
  static const IconData bar_chart_outlined = IconData(0xf187, fontFamily: 'Lucide'); // barChart3
  static const IconData bar_chart_rounded = IconData(0xf187, fontFamily: 'Lucide'); // barChart3
  static const IconData breakfast_dining = IconData(0xf294, fontFamily: 'Lucide'); // eggFried
  static const IconData brightness_6_outlined = IconData(0xf250, fontFamily: 'Lucide'); // contrast
  static const IconData cake = IconData(0xf1cf, fontFamily: 'Lucide'); // cake
  static const IconData calculate_outlined = IconData(0xf1d1, fontFamily: 'Lucide'); // calculator
  static const IconData calendar_month_outlined = IconData(0xf1d2, fontFamily: 'Lucide'); // calendar
  static const IconData card_giftcard = IconData(0xf32c, fontFamily: 'Lucide'); // gift
  static const IconData card_giftcard_outlined = IconData(0xf32c, fontFamily: 'Lucide'); // gift
  static const IconData chat_outlined = IconData(0xf3cd, fontFamily: 'Lucide'); // messageCircle
  static const IconData check = IconData(0xf1ee, fontFamily: 'Lucide'); // check
  static const IconData check_circle_outline = IconData(0xf1f0, fontFamily: 'Lucide'); // checkCircle
  static const IconData chevron_right = IconData(0xf1fb, fontFamily: 'Lucide'); // chevronRight
  static const IconData circle = IconData(0xf20b, fontFamily: 'Lucide'); // circle
  static const IconData clear = IconData(0xf59e, fontFamily: 'Lucide'); // x
  static const IconData close = IconData(0xf59e, fontFamily: 'Lucide'); // x
  static const IconData cloud_done_outlined = IconData(0xf22e, fontFamily: 'Lucide'); // cloud
  static const IconData cloud_off_outlined = IconData(0xf236, fontFamily: 'Lucide'); // cloudOff
  static const IconData cloud_outlined = IconData(0xf22e, fontFamily: 'Lucide'); // cloud
  static const IconData cloud_sync_outlined = IconData(0xf562, fontFamily: 'Lucide'); // uploadCloud
  static const IconData coffee = IconData(0xf195, fontFamily: 'Lucide'); // bean
  static const IconData coffee_maker = IconData(0xf26a, fontFamily: 'Lucide'); // cupSoda
  static const IconData delete_outline = IconData(0xf546, fontFamily: 'Lucide'); // trash2
  static const IconData delivery_dining_outlined = IconData(0xf1a2, fontFamily: 'Lucide'); // bike
  static const IconData dinner_dining = IconData(0xf576, fontFamily: 'Lucide'); // utensils
  static const IconData done_all = IconData(0xf1ef, fontFamily: 'Lucide'); // checkCheck
  static const IconData edit_outlined = IconData(0xf43d, fontFamily: 'Lucide'); // pencil
  static const IconData emoji_events_outlined = IconData(0xf54e, fontFamily: 'Lucide'); // trophy
  static const IconData emoji_food_beverage = IconData(0xf216, fontFamily: 'Lucide'); // citrus
  static const IconData error_outline = IconData(0xf10b, fontFamily: 'Lucide'); // alertCircle
  static const IconData expand_more = IconData(0xf1f5, fontFamily: 'Lucide'); // chevronDown
  static const IconData fact_check_outlined = IconData(0xf39c, fontFamily: 'Lucide'); // listChecks
  static const IconData fastfood = IconData(0xf49a, fontFamily: 'Lucide'); // sandwich
  static const IconData group = IconData(0xf574, fontFamily: 'Lucide'); // users
  static const IconData groups = IconData(0xf575, fontFamily: 'Lucide'); // users2
  static const IconData groups_outlined = IconData(0xf575, fontFamily: 'Lucide'); // users2
  static const IconData history = IconData(0xf35d, fontFamily: 'Lucide'); // history
  static const IconData home = IconData(0xf35e, fontFamily: 'Lucide'); // home
  static const IconData home_outlined = IconData(0xf35e, fontFamily: 'Lucide'); // home
  static const IconData home_rounded = IconData(0xf35e, fontFamily: 'Lucide'); // home
  static const IconData info_outline = IconData(0xf36e, fontFamily: 'Lucide'); // info
  static const IconData info_outlined = IconData(0xf36e, fontFamily: 'Lucide'); // info
  static const IconData inventory = IconData(0xf414, fontFamily: 'Lucide'); // package
  static const IconData inventory_2 = IconData(0xf130, fontFamily: 'Lucide'); // archive
  static const IconData inventory_2_outlined = IconData(0xf130, fontFamily: 'Lucide'); // archive
  static const IconData inventory_2_rounded = IconData(0xf130, fontFamily: 'Lucide'); // archive
  static const IconData inventory_outlined = IconData(0xf414, fontFamily: 'Lucide'); // package
  static const IconData key_outlined = IconData(0xf376, fontFamily: 'Lucide'); // key
  static const IconData local_cafe = IconData(0xf243, fontFamily: 'Lucide'); // coffee
  static const IconData local_drink = IconData(0xf599, fontFamily: 'Lucide'); // wine
  static const IconData local_offer_outlined = IconData(0xf521, fontFamily: 'Lucide'); // tag
  static const IconData menu = IconData(0xf3ca, fontFamily: 'Lucide'); // menu
  static const IconData more_vert = IconData(0xf3ee, fontFamily: 'Lucide'); // moreVertical
  static const IconData notifications_none_outlined = IconData(0xf19c, fontFamily: 'Lucide'); // bell
  static const IconData notifications_outlined = IconData(0xf19c, fontFamily: 'Lucide'); // bell
  static const IconData notifications_rounded = IconData(0xf19c, fontFamily: 'Lucide'); // bell
  static const IconData payments_outlined = IconData(0xf184, fontFamily: 'Lucide'); // banknote
  static const IconData percent_outlined = IconData(0xf43e, fontFamily: 'Lucide'); // percent
  static const IconData phone_outlined = IconData(0xf440, fontFamily: 'Lucide'); // phone
  static const IconData person_outline = IconData(0xf564, fontFamily: 'Lucide'); // user
  static const IconData photo_camera_outlined = IconData(0xf1df, fontFamily: 'Lucide'); // camera
  static const IconData photo_library_outlined = IconData(0xf365, fontFamily: 'Lucide'); // image
  static const IconData pin_outlined = IconData(0xf450, fontFamily: 'Lucide'); // pin
  static const IconData point_of_sale = IconData(0xf4c8, fontFamily: 'Lucide'); // shoppingCart
  static const IconData point_of_sale_outlined = IconData(0xf4c8, fontFamily: 'Lucide'); // shoppingCart
  static const IconData point_of_sale_rounded = IconData(0xf4c8, fontFamily: 'Lucide'); // shoppingCart
  static const IconData print_outlined = IconData(0xf46b, fontFamily: 'Lucide'); // printer
  static const IconData qr_code_2 = IconData(0xf46e, fontFamily: 'Lucide'); // qrCode
  static const IconData qr_code_2_outlined = IconData(0xf46e, fontFamily: 'Lucide'); // qrCode
  static const IconData radio_button_checked = IconData(0xf20e, fontFamily: 'Lucide'); // circleDot
  static const IconData radio_button_unchecked = IconData(0xf20b, fontFamily: 'Lucide'); // circle
  static const IconData ramen_dining = IconData(0xf4e4, fontFamily: 'Lucide'); // soup
  static const IconData receipt_long_outlined = IconData(0xf477, fontFamily: 'Lucide'); // receipt
  static const IconData receipt_outlined = IconData(0xf477, fontFamily: 'Lucide'); // receipt
  static const IconData refresh = IconData(0xf480, fontFamily: 'Lucide'); // refreshCw
  static const IconData remove = IconData(0xf3dc, fontFamily: 'Lucide'); // minus
  static const IconData restaurant_menu_outlined = IconData(0xf576, fontFamily: 'Lucide'); // utensils
  static const IconData restaurant_menu_rounded = IconData(0xf576, fontFamily: 'Lucide'); // utensils
  static const IconData rice_bowl = IconData(0xf499, fontFamily: 'Lucide'); // salad
  static const IconData rocket_launch_outlined = IconData(0xf48d, fontFamily: 'Lucide'); // rocket
  static const IconData room_service_outlined = IconData(0xf24b, fontFamily: 'Lucide'); // conciergeBell
  static const IconData save_alt = IconData(0xf287, fontFamily: 'Lucide'); // download
  static const IconData savings_outlined = IconData(0xf44c, fontFamily: 'Lucide'); // piggyBank
  static const IconData scale_outlined = IconData(0xf49f, fontFamily: 'Lucide'); // scale
  static const IconData schedule_outlined = IconData(0xf221, fontFamily: 'Lucide'); // clock
  static const IconData search = IconData(0xf4ad, fontFamily: 'Lucide'); // search
  static const IconData search_off_outlined = IconData(0xf4b0, fontFamily: 'Lucide'); // searchSlash
  static const IconData search_rounded = IconData(0xf4ad, fontFamily: 'Lucide'); // search
  static const IconData sell_outlined = IconData(0xf521, fontFamily: 'Lucide'); // tag
  static const IconData set_meal = IconData(0xf2e3, fontFamily: 'Lucide'); // fish
  static const IconData settings = IconData(0xf4b9, fontFamily: 'Lucide'); // settings
  static const IconData settings_outlined = IconData(0xf4b9, fontFamily: 'Lucide'); // settings
  static const IconData settings_rounded = IconData(0xf4b9, fontFamily: 'Lucide'); // settings
  static const IconData share_outlined = IconData(0xf4bd, fontFamily: 'Lucide'); // share2
  static const IconData shopping_bag_outlined = IconData(0xf4c7, fontFamily: 'Lucide'); // shoppingBag
  static const IconData shopping_basket_outlined = IconData(0xf4c8, fontFamily: 'Lucide'); // shoppingCart
  static const IconData show_chart = IconData(0xf396, fontFamily: 'Lucide'); // lineChart
  static const IconData show_chart_outlined = IconData(0xf396, fontFamily: 'Lucide'); // lineChart
  static const IconData soup_kitchen = IconData(0xf1f3, fontFamily: 'Lucide'); // chefHat
  static const IconData soup_kitchen_outlined = IconData(0xf1f3, fontFamily: 'Lucide'); // chefHat
  static const IconData soup_kitchen_rounded = IconData(0xf1f3, fontFamily: 'Lucide'); // chefHat
  static const IconData store_outlined = IconData(0xf509, fontFamily: 'Lucide'); // store
  static const IconData storefront = IconData(0xf509, fontFamily: 'Lucide'); // store
  static const IconData storefront_outlined = IconData(0xf509, fontFamily: 'Lucide'); // store
  static const IconData swap_horiz_outlined = IconData(0xf152, fontFamily: 'Lucide'); // arrowLeftRight
  static const IconData sync = IconData(0xf47e, fontFamily: 'Lucide'); // refreshCcw
  static const IconData system_update_alt = IconData(0xf14b, fontFamily: 'Lucide'); // arrowDownToLine
  static const IconData system_update_alt_outlined = IconData(0xf14b, fontFamily: 'Lucide'); // arrowDownToLine
  static const IconData table_bar_outlined = IconData(0xf51d, fontFamily: 'Lucide'); // table2
  static const IconData table_chart_outlined = IconData(0xf51c, fontFamily: 'Lucide'); // table
  static const IconData table_restaurant = IconData(0xf51d, fontFamily: 'Lucide'); // table2
  static const IconData table_restaurant_outlined = IconData(0xf51d, fontFamily: 'Lucide'); // table2
  static const IconData table_restaurant_rounded = IconData(0xf51d, fontFamily: 'Lucide'); // table2
  static const IconData tapas = IconData(0xf251, fontFamily: 'Lucide'); // cookie
  static const IconData trending_down = IconData(0xf54b, fontFamily: 'Lucide'); // trendingDown
  static const IconData trending_up = IconData(0xf54c, fontFamily: 'Lucide'); // trendingUp
  static const IconData trending_up_outlined = IconData(0xf54c, fontFamily: 'Lucide'); // trendingUp
  static const IconData upload_file_outlined = IconData(0xf561, fontFamily: 'Lucide'); // upload
  static const IconData visibility_off_outlined = IconData(0xf29d, fontFamily: 'Lucide'); // eyeOff
  static const IconData visibility_outlined = IconData(0xf29c, fontFamily: 'Lucide'); // eye
  static const IconData warehouse_outlined = IconData(0xf58e, fontFamily: 'Lucide'); // warehouse
  static const IconData warning_amber_outlined = IconData(0xf10d, fontFamily: 'Lucide'); // alertTriangle
  static const IconData wifi_off_outlined = IconData(0xf597, fontFamily: 'Lucide'); // wifiOff
}
