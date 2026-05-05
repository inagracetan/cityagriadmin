
class ActivityTemplate {
  final String name;
  final String sector;
  final String? subSector;
  final List<TemplateItem> items;

  ActivityTemplate({
    required this.name,
    required this.sector,
    this.subSector,
    required this.items,
  });
}

class TemplateItem {
  final String name;
  final String unit;
  final double q1;
  final double q2;
  final double q3;
  final double q4;
  final double price;

  TemplateItem({
    required this.name,
    required this.unit,
    this.q1 = 0,
    this.q2 = 0,
    this.q3 = 0,
    this.q4 = 0,
    required this.price,
  });
}

class ActivityTemplates {
  static final List<ActivityTemplate> templates = [
    ActivityTemplate(
      name: 'Upland Hybrid Rice Techno Demo Establishment',
      sector: 'Crop Section',
      subSector: 'Rice',
      items: [
        TemplateItem(name: 'Hybrid Rice Seeds (15kg/bag)', unit: 'bag', q1: 1, price: 5000.00),
        TemplateItem(name: 'Organic Fertilizer Vermicast (Class A)', unit: 'bags', q1: 15, price: 350.00),
        TemplateItem(name: 'Meals and Snacks (Launching)', unit: 'cover', q1: 37, price: 280.00),
        TemplateItem(name: '14-14-14 Fertilizer', unit: 'bags', q1: 2, price: 2500.00),
        TemplateItem(name: '16-20-0 Fertilizer', unit: 'bags', q1: 2, price: 1800.00),
        TemplateItem(name: 'Insecticide, Herbicide', unit: 'bottle', q1: 5, price: 600.00),
        TemplateItem(name: 'Empty Sacks', unit: 'pc', q1: 100, price: 25.00),
        TemplateItem(name: 'Tarpaulin (8x10 ft.)', unit: 'pc', q1: 1, price: 1000.00),
        TemplateItem(name: 'Meals and Snacks (Field Day)', unit: 'cover', q3: 50, price: 280.00),
        TemplateItem(name: 'Roasted Pig (Lechon)', unit: 'pc', q2: 1, price: 12000.00),
      ],
    ),
    ActivityTemplate(
      name: 'FFS on Corn Production and Management',
      sector: 'Crop Section',
      subSector: 'Corn',
      items: [
        TemplateItem(name: 'Lime Fertilizer', unit: 'bags', q1: 20, price: 150.00),
        TemplateItem(name: 'Organic Fertilizer (Vermicast)', unit: 'bags', q1: 20, price: 400.00),
        TemplateItem(name: 'Meals for Graduation', unit: 'cover', q1: 70, price: 200.00),
        TemplateItem(name: 'Hybrid Corn Seeds', unit: 'bags', q1: 1, price: 7000.00),
        TemplateItem(name: '46-0-0 Urea', unit: 'bags', q1: 4, price: 2500.00),
        TemplateItem(name: 'Herbicide', unit: 'gal', q1: 2, price: 1500.00),
        TemplateItem(name: 'Tarpaulin (8x10)', unit: 'pc', q1: 1, price: 500.00),
        TemplateItem(name: 'Snacks (AM/PM)', unit: 'cover', q1: 140, price: 80.00),
      ],
    ),
    ActivityTemplate(
      name: 'FFS on Coffee & Vegetable Production',
      sector: 'Crop Section',
      subSector: 'HVCDP',
      items: [
        TemplateItem(name: 'Meals', unit: 'cover', q2: 70, price: 200.00),
        TemplateItem(name: 'Snacks', unit: 'cover', q2: 140, price: 80.00),
        TemplateItem(name: 'Fertilizers (complete) 14-14-14', unit: 'bags', q2: 10, price: 2500.00),
        TemplateItem(name: 'Organic Fertilizer (Vermicast)', unit: 'bags', q2: 50, price: 350.00),
        TemplateItem(name: 'Grafting Knife', unit: 'pcs', q2: 10, price: 350.00),
        TemplateItem(name: 'Pruning Shears', unit: 'pcs', q2: 10, price: 350.00),
        TemplateItem(name: 'Vegetable Seeds', unit: 'packs', q2: 100, price: 50.00),
        TemplateItem(name: 'Knapsack Sprayer', unit: 'unit', q2: 2, price: 2500.00),
      ],
    ),
    ActivityTemplate(
      name: 'Organic Agriculture Technology Demonstration',
      sector: 'Crop Section',
      subSector: 'Organic Program',
      items: [
        TemplateItem(name: 'Organic Fertilizer Vermicast', unit: 'bags', q1: 50, price: 350.00),
        TemplateItem(name: 'Organic Seeds', unit: 'packs', q1: 100, price: 100.00),
        TemplateItem(name: 'Meals (Launching)', unit: 'cover', q1: 50, price: 250.00),
        TemplateItem(name: 'Snacks', unit: 'cover', q1: 100, price: 80.00),
        TemplateItem(name: 'Laminated Sacks', unit: 'pcs', q1: 50, price: 150.00),
        TemplateItem(name: 'Molasses', unit: 'drum', q1: 2, price: 6000.00),
      ],
    ),
    ActivityTemplate(
      name: 'Tilapia Processing and Value Adding Training',
      sector: 'Inland Fisheries Section',
      items: [
        TemplateItem(name: 'Meals', unit: 'cover', q2: 50, price: 250.00),
        TemplateItem(name: 'Snacks', unit: 'cover', q2: 100, price: 80.00),
        TemplateItem(name: 'Processing Kit (Stainless Bowl, Knife)', unit: 'set', q2: 10, price: 1500.00),
        TemplateItem(name: 'Tilapia for Processing', unit: 'kgs', q2: 50, price: 120.00),
      ],
    ),
    ActivityTemplate(
      name: 'Workshop on Sustainable Development Goals',
      sector: 'Administrative Support Services Unit',
      items: [
        TemplateItem(name: 'Meals (3 days)', unit: 'cover', q3: 300, price: 250.00),
        TemplateItem(name: 'Snacks', unit: 'cover', q3: 600, price: 80.00),
        TemplateItem(name: 'Training Materials / Kits', unit: 'sets', q3: 100, price: 500.00),
        TemplateItem(name: 'Honorarium (Guest Speakers)', unit: 'pax', q3: 3, price: 5000.00),
        TemplateItem(name: 'Venue Rental', unit: 'day', q3: 3, price: 5000.00),
      ],
    ),
  ];
}
