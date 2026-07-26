class ProductPack {
  const ProductPack({
    required this.name,
    required this.quantityLabel,
    required this.image,
    required this.description,
    required this.idealFor,
    this.cans,
  });

  final String name;
  final String quantityLabel;
  final String image;
  final String description;
  final String idealFor;
  final int? cans;

  bool get isCustom => cans == null;
}

const productPacks = <ProductPack>[
  ProductPack(
    name: 'Mini Event Pack',
    quantityLabel: '20 Cans',
    cans: 20,
    image: 'assets/images/Products/Mini Event Pack.png',
    description:
        'A compact water supply pack for small celebrations and gatherings.',
    idealFor: 'Small functions, family events and intimate celebrations',
  ),
  ProductPack(
    name: 'Standard Event Pack',
    quantityLabel: '50 Cans',
    cans: 50,
    image: 'assets/images/Products/Standard Event Pack.png',
    description:
        'A balanced event pack with enough drinking water for medium gatherings.',
    idealFor: 'Birthdays, community functions and medium-size events',
  ),
  ProductPack(
    name: 'Large Event Pack',
    quantityLabel: '100 Cans',
    cans: 100,
    image: 'assets/images/Products/Large Event Pack.png',
    description:
        'Reliable bulk water supply designed for busy full-day celebrations.',
    idealFor: 'Weddings, receptions and large public functions',
  ),
  ProductPack(
    name: 'Jumbo Event Pack',
    quantityLabel: '150 Cans',
    cans: 150,
    image: 'assets/images/Products/Jumbo Event Pack.png',
    description:
        'Our largest ready pack for high-attendance events and celebrations.',
    idealFor: 'Large weddings, festivals and major community events',
  ),
  ProductPack(
    name: 'Custom Event Pack',
    quantityLabel: 'Choose Quantity',
    image: 'assets/images/Products/Custom Event Pack.png',
    description:
        'Choose the exact number of cans needed for your unique event.',
    idealFor: 'Any event requiring a personalised water quantity',
  ),
];
