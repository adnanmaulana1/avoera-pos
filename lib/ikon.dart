import 'package:flutter/widgets.dart';
// ignore_for_file: constant_identifier_names

/// Ikon aplikasi: set Phosphor (SVG profesional yang dijadikan
/// huruf ikon), menggantikan ikon bawaan Material sejak v0.13.0
/// atas pilihan Adnan — gaya garis yang lebih segar.
///
/// Nama field SENGAJA meniru nama ikon Material lama supaya
/// seluruh tempat pemakaian cukup berganti awalan `Ikon.`
/// menjadi `Ikon.`. Varian "isi" memakai huruf Phosphor-Fill
/// dengan kode yang sama (pasangan terpilih/aktif).
/// Berkas huruf di assets/fonts; build release memangkasnya
/// otomatis ke ikon yang benar-benar dipakai.
class Ikon {
  Ikon._();

  static const IconData account_balance_outlined = IconData(0xe0b4, fontFamily: 'Phosphor'); // bank
  static const IconData account_balance_wallet_outlined = IconData(0xe68a, fontFamily: 'Phosphor'); // wallet
  static const IconData account_balance_wallet_rounded = IconData(0xe68a, fontFamily: 'PhosphorFill'); // wallet
  static const IconData add = IconData(0xe3d4, fontFamily: 'Phosphor'); // plus
  static const IconData add_box_outlined = IconData(0xed4a, fontFamily: 'Phosphor'); // plus-square
  static const IconData add_business_outlined = IconData(0xe470, fontFamily: 'Phosphor'); // storefront
  static const IconData add_rounded = IconData(0xe3d4, fontFamily: 'Phosphor'); // plus
  static const IconData arrow_back = IconData(0xe058, fontFamily: 'Phosphor'); // arrow-left
  static const IconData arrow_downward_outlined = IconData(0xe03e, fontFamily: 'Phosphor'); // arrow-down
  static const IconData arrow_upward_outlined = IconData(0xe08e, fontFamily: 'Phosphor'); // arrow-up
  static const IconData backspace_outlined = IconData(0xe0ae, fontFamily: 'Phosphor'); // backspace
  static const IconData bakery_dining = IconData(0xe81c, fontFamily: 'Phosphor'); // bread
  static const IconData balance_outlined = IconData(0xe750, fontFamily: 'Phosphor'); // scales
  static const IconData bar_chart = IconData(0xe150, fontFamily: 'PhosphorFill'); // chart-bar
  static const IconData bar_chart_outlined = IconData(0xe150, fontFamily: 'Phosphor'); // chart-bar
  static const IconData bar_chart_rounded = IconData(0xe150, fontFamily: 'PhosphorFill'); // chart-bar
  static const IconData breakfast_dining = IconData(0xe812, fontFamily: 'Phosphor'); // egg
  static const IconData brightness_6_outlined = IconData(0xe18c, fontFamily: 'Phosphor'); // circle-half
  static const IconData cake = IconData(0xe780, fontFamily: 'Phosphor'); // cake
  static const IconData calculate_outlined = IconData(0xe538, fontFamily: 'Phosphor'); // calculator
  static const IconData calendar_month_outlined = IconData(0xe108, fontFamily: 'Phosphor'); // calendar
  static const IconData card_giftcard = IconData(0xe276, fontFamily: 'Phosphor'); // gift
  static const IconData card_giftcard_outlined = IconData(0xe276, fontFamily: 'Phosphor'); // gift
  static const IconData chat_outlined = IconData(0xe15c, fontFamily: 'Phosphor'); // chat
  static const IconData check = IconData(0xe182, fontFamily: 'Phosphor'); // check
  static const IconData check_circle_outline = IconData(0xe184, fontFamily: 'Phosphor'); // check-circle
  static const IconData chevron_right = IconData(0xe13a, fontFamily: 'Phosphor'); // caret-right
  static const IconData circle = IconData(0xe18a, fontFamily: 'Phosphor'); // circle
  static const IconData clear = IconData(0xe4f6, fontFamily: 'Phosphor'); // x
  static const IconData close = IconData(0xe4f6, fontFamily: 'Phosphor'); // x
  static const IconData cloud_done_outlined = IconData(0xe1b0, fontFamily: 'Phosphor'); // cloud-check
  static const IconData cloud_off_outlined = IconData(0xe1b6, fontFamily: 'Phosphor'); // cloud-slash
  static const IconData cloud_outlined = IconData(0xe1aa, fontFamily: 'Phosphor'); // cloud
  static const IconData cloud_sync_outlined = IconData(0xe1ae, fontFamily: 'Phosphor'); // cloud-arrow-up
  static const IconData coffee = IconData(0xe1c0, fontFamily: 'Phosphor'); // coffee-bean
  static const IconData coffee_maker = IconData(0xe8e6, fontFamily: 'Phosphor'); // tea-bag
  static const IconData delete_outline = IconData(0xe4a6, fontFamily: 'Phosphor'); // trash
  static const IconData dinner_dining = IconData(0xe262, fontFamily: 'Phosphor'); // fork-knife
  static const IconData done_all = IconData(0xe53a, fontFamily: 'Phosphor'); // checks
  static const IconData edit_outlined = IconData(0xe3b4, fontFamily: 'Phosphor'); // pencil-simple
  static const IconData emoji_events_outlined = IconData(0xe67e, fontFamily: 'Phosphor'); // trophy
  static const IconData emoji_food_beverage = IconData(0xed36, fontFamily: 'Phosphor'); // orange-slice
  static const IconData error_outline = IconData(0xe4e2, fontFamily: 'Phosphor'); // warning-circle
  static const IconData expand_more = IconData(0xe136, fontFamily: 'Phosphor'); // caret-down
  static const IconData fact_check_outlined = IconData(0xeadc, fontFamily: 'Phosphor'); // list-checks
  static const IconData fastfood = IconData(0xe790, fontFamily: 'Phosphor'); // hamburger
  static const IconData group = IconData(0xe4d6, fontFamily: 'Phosphor'); // users
  static const IconData groups = IconData(0xe68e, fontFamily: 'Phosphor'); // users-three
  static const IconData groups_outlined = IconData(0xe68e, fontFamily: 'Phosphor'); // users-three
  static const IconData history = IconData(0xe1a0, fontFamily: 'Phosphor'); // clock-counter-clockwise
  static const IconData home = IconData(0xe2c2, fontFamily: 'PhosphorFill'); // house
  static const IconData home_outlined = IconData(0xe2c2, fontFamily: 'Phosphor'); // house
  static const IconData home_rounded = IconData(0xe2c2, fontFamily: 'PhosphorFill'); // house
  static const IconData info_outline = IconData(0xe2ce, fontFamily: 'Phosphor'); // info
  static const IconData info_outlined = IconData(0xe2ce, fontFamily: 'Phosphor'); // info
  static const IconData inventory = IconData(0xe390, fontFamily: 'PhosphorFill'); // package
  static const IconData inventory_2 = IconData(0xe00c, fontFamily: 'PhosphorFill'); // archive
  static const IconData inventory_2_outlined = IconData(0xe00c, fontFamily: 'Phosphor'); // archive
  static const IconData inventory_2_rounded = IconData(0xe00c, fontFamily: 'PhosphorFill'); // archive
  static const IconData inventory_outlined = IconData(0xe390, fontFamily: 'Phosphor'); // package
  static const IconData key_outlined = IconData(0xe2d6, fontFamily: 'Phosphor'); // key
  static const IconData local_cafe = IconData(0xe1c2, fontFamily: 'Phosphor'); // coffee
  static const IconData local_drink = IconData(0xe6b2, fontFamily: 'Phosphor'); // wine
  static const IconData local_offer_outlined = IconData(0xe478, fontFamily: 'Phosphor'); // tag
  static const IconData menu = IconData(0xe2f0, fontFamily: 'Phosphor'); // list
  static const IconData more_vert = IconData(0xe208, fontFamily: 'Phosphor'); // dots-three-vertical
  static const IconData notifications_none_outlined = IconData(0xe0ce, fontFamily: 'Phosphor'); // bell
  static const IconData notifications_outlined = IconData(0xe0ce, fontFamily: 'Phosphor'); // bell
  static const IconData notifications_rounded = IconData(0xe0ce, fontFamily: 'PhosphorFill'); // bell
  static const IconData payments_outlined = IconData(0xe588, fontFamily: 'Phosphor'); // money
  static const IconData percent_outlined = IconData(0xe3b6, fontFamily: 'Phosphor'); // percent
  static const IconData person_outline = IconData(0xe4c2, fontFamily: 'Phosphor'); // user
  static const IconData photo_camera_outlined = IconData(0xe10e, fontFamily: 'Phosphor'); // camera
  static const IconData photo_library_outlined = IconData(0xe836, fontFamily: 'Phosphor'); // images
  static const IconData pin_outlined = IconData(0xe3e2, fontFamily: 'Phosphor'); // push-pin
  static const IconData point_of_sale = IconData(0xed80, fontFamily: 'PhosphorFill'); // cash-register
  static const IconData point_of_sale_outlined = IconData(0xed80, fontFamily: 'Phosphor'); // cash-register
  static const IconData point_of_sale_rounded = IconData(0xed80, fontFamily: 'PhosphorFill'); // cash-register
  static const IconData print_outlined = IconData(0xe3dc, fontFamily: 'Phosphor'); // printer
  static const IconData qr_code_2 = IconData(0xe3e6, fontFamily: 'PhosphorFill'); // qr-code
  static const IconData qr_code_2_outlined = IconData(0xe3e6, fontFamily: 'Phosphor'); // qr-code
  static const IconData radio_button_checked = IconData(0xeb08, fontFamily: 'Phosphor'); // radio-button
  static const IconData radio_button_unchecked = IconData(0xe18a, fontFamily: 'Phosphor'); // circle
  static const IconData ramen_dining = IconData(0xe8e4, fontFamily: 'Phosphor'); // bowl-steam
  static const IconData receipt_long_outlined = IconData(0xe3ec, fontFamily: 'Phosphor'); // receipt
  static const IconData receipt_outlined = IconData(0xe3ec, fontFamily: 'Phosphor'); // receipt
  static const IconData refresh = IconData(0xe036, fontFamily: 'Phosphor'); // arrow-clockwise
  static const IconData remove = IconData(0xe32a, fontFamily: 'Phosphor'); // minus
  static const IconData restaurant_menu_outlined = IconData(0xe262, fontFamily: 'Phosphor'); // fork-knife
  static const IconData restaurant_menu_rounded = IconData(0xe262, fontFamily: 'Phosphor'); // fork-knife
  static const IconData rice_bowl = IconData(0xeaa4, fontFamily: 'Phosphor'); // bowl-food
  static const IconData rocket_launch_outlined = IconData(0xe3fe, fontFamily: 'Phosphor'); // rocket-launch
  static const IconData room_service_outlined = IconData(0xe7de, fontFamily: 'Phosphor'); // call-bell
  static const IconData save_alt = IconData(0xe20c, fontFamily: 'Phosphor'); // download-simple
  static const IconData savings_outlined = IconData(0xea04, fontFamily: 'Phosphor'); // piggy-bank
  static const IconData scale_outlined = IconData(0xe750, fontFamily: 'Phosphor'); // scales
  static const IconData schedule_outlined = IconData(0xe19a, fontFamily: 'Phosphor'); // clock
  static const IconData search = IconData(0xe30c, fontFamily: 'Phosphor'); // magnifying-glass
  static const IconData search_off_outlined = IconData(0xe30c, fontFamily: 'Phosphor'); // magnifying-glass
  static const IconData search_rounded = IconData(0xe30c, fontFamily: 'Phosphor'); // magnifying-glass
  static const IconData sell_outlined = IconData(0xe478, fontFamily: 'Phosphor'); // tag
  static const IconData set_meal = IconData(0xe728, fontFamily: 'Phosphor'); // fish
  static const IconData settings = IconData(0xe270, fontFamily: 'PhosphorFill'); // gear
  static const IconData settings_outlined = IconData(0xe270, fontFamily: 'Phosphor'); // gear
  static const IconData settings_rounded = IconData(0xe270, fontFamily: 'PhosphorFill'); // gear
  static const IconData share_outlined = IconData(0xe408, fontFamily: 'Phosphor'); // share-network
  static const IconData shopping_bag_outlined = IconData(0xe416, fontFamily: 'Phosphor'); // shopping-bag
  static const IconData shopping_basket_outlined = IconData(0xe964, fontFamily: 'Phosphor'); // basket
  static const IconData show_chart = IconData(0xe154, fontFamily: 'PhosphorFill'); // chart-line
  static const IconData show_chart_outlined = IconData(0xe154, fontFamily: 'Phosphor'); // chart-line
  static const IconData soup_kitchen = IconData(0xe764, fontFamily: 'PhosphorFill'); // cooking-pot
  static const IconData soup_kitchen_outlined = IconData(0xe764, fontFamily: 'Phosphor'); // cooking-pot
  static const IconData soup_kitchen_rounded = IconData(0xe764, fontFamily: 'PhosphorFill'); // cooking-pot
  static const IconData store_outlined = IconData(0xe470, fontFamily: 'Phosphor'); // storefront
  static const IconData storefront = IconData(0xe470, fontFamily: 'PhosphorFill'); // storefront
  static const IconData storefront_outlined = IconData(0xe470, fontFamily: 'Phosphor'); // storefront
  static const IconData swap_horiz_outlined = IconData(0xe0a0, fontFamily: 'Phosphor'); // arrows-left-right
  static const IconData sync = IconData(0xe094, fontFamily: 'Phosphor'); // arrows-clockwise
  static const IconData system_update_alt = IconData(0xe010, fontFamily: 'Phosphor'); // tray-arrow-down
  static const IconData system_update_alt_outlined = IconData(0xe010, fontFamily: 'Phosphor'); // tray-arrow-down
  static const IconData table_bar_outlined = IconData(0xe476, fontFamily: 'Phosphor'); // table
  static const IconData table_chart_outlined = IconData(0xe476, fontFamily: 'Phosphor'); // table
  static const IconData table_restaurant = IconData(0xe476, fontFamily: 'PhosphorFill'); // table
  static const IconData table_restaurant_outlined = IconData(0xe476, fontFamily: 'Phosphor'); // table
  static const IconData table_restaurant_rounded = IconData(0xe476, fontFamily: 'PhosphorFill'); // table
  static const IconData tapas = IconData(0xe6ca, fontFamily: 'Phosphor'); // cookie
  static const IconData trending_down = IconData(0xe4ac, fontFamily: 'Phosphor'); // trend-down
  static const IconData trending_up = IconData(0xe4ae, fontFamily: 'PhosphorFill'); // trend-up
  static const IconData trending_up_outlined = IconData(0xe4ae, fontFamily: 'Phosphor'); // trend-up
  static const IconData visibility_off_outlined = IconData(0xe224, fontFamily: 'Phosphor'); // eye-slash
  static const IconData visibility_outlined = IconData(0xe220, fontFamily: 'Phosphor'); // eye
  static const IconData warehouse_outlined = IconData(0xecd4, fontFamily: 'Phosphor'); // warehouse
  static const IconData warning_amber_outlined = IconData(0xe4e0, fontFamily: 'Phosphor'); // warning
  static const IconData wifi_off_outlined = IconData(0xe4f2, fontFamily: 'Phosphor'); // wifi-slash
}
