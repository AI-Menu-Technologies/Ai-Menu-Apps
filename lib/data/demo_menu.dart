import '../models/menu_item.dart';

const List<MenuItem> demoMenu = [
  // ==================== ГОРЯЧИЕ БЛЮДА ====================

  MenuItem(
    id: 'hot_001',
    name: 'Стейк',
    description: 'Сочный стейк с гарниром',
    price: 120000,
    category: 'Горячие блюда',
  ),

  MenuItem(
    id: 'hot_002',
    name: 'Мясо по-бакински',
    description: 'Нежное мясо с ароматными специями',
    price: 95000,
    category: 'Горячие блюда',
  ),

  // ==================== ГОРЯЧИЕ ЗАКУСКИ ====================

  MenuItem(
    id: 'hot_snack_001',
    name: 'Крылышки BBQ',
    description: 'Куриные крылышки в соусе BBQ',
    price: 65000,
    category: 'Горячие закуски',
  ),

  MenuItem(
    id: 'hot_snack_002',
    name: 'Наггетсы',
    description: 'Хрустящие куриные наггетсы',
    price: 55000,
    category: 'Горячие закуски',
  ),

  // ==================== ХОЛОДНЫЕ ЗАКУСКИ ====================

  MenuItem(
    id: 'cold_001',
    name: 'Мясная тарелка',
    description: 'Ассорти мясных деликатесов',
    price: 140000,
    category: 'Холодные закуски',
  ),

  MenuItem(
    id: 'cold_002',
    name: 'Сырная тарелка',
    description: 'Ассорти сыров, орехи, мёд и виноград',
    price: 130000,
    category: 'Холодные закуски',
  ),

  // ==================== ДЕСЕРТЫ ====================

  MenuItem(
    id: 'dessert_001',
    name: 'Чизкейк',
    description: 'Нежный сливочный чизкейк',
    price: 45000,
    category: 'Десерты',
  ),

  MenuItem(
    id: 'dessert_002',
    name: 'Шоколадный фондан',
    description: 'Тёплый шоколадный десерт',
    price: 50000,
    category: 'Десерты',
  ),

  // ==================== ГАРНИРЫ ====================

  MenuItem(
    id: 'side_001',
    name: 'Картофель фри',
    description: 'Хрустящий картофель фри',
    price: 30000,
    category: 'Гарниры',
  ),

  MenuItem(
    id: 'side_002',
    name: 'Овощи на гриле',
    description: 'Свежие овощи, приготовленные на гриле',
    price: 40000,
    category: 'Гарниры',
  ),

  // ==================== СОУСЫ ====================

  MenuItem(
    id: 'sauce_001',
    name: 'Сырный соус',
    description: 'Нежный сырный соус',
    price: 15000,
    category: 'Соусы',
  ),

  MenuItem(
    id: 'sauce_002',
    name: 'BBQ соус',
    description: 'Фирменный соус BBQ',
    price: 15000,
    category: 'Соусы',
  ),

  // ==================== ХЛЕБ ====================

  MenuItem(
    id: 'bread_001',
    name: 'Хлебная корзина',
    description: 'Ассорти свежего хлеба',
    price: 20000,
    category: 'Хлеб',
  ),

  // ==================== БАР ====================

  MenuItem(
    id: 'bar_001',
    name: 'Лимонад',
    description: 'Освежающий домашний лимонад',
    price: 30000,
    category: 'Безалкогольные',
  ),

  MenuItem(
    id: 'bar_002',
    name: 'Мохито',
    description: 'Освежающий коктейль с мятой и лаймом',
    price: 50000,
    category: 'Коктейли',
  ),

  MenuItem(
    id: 'bar_003',
    name: 'Крафтовое пиво',
    description: 'Охлаждённое крафтовое пиво',
    price: 45000,
    category: 'Пиво',
  ),
];