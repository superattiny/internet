# ================================================
# models.py — Barcha ma'lumotlar bazasi modellari
# Har bir klass = bitta jadval
# ================================================

from datetime import datetime
from typing import Optional
from sqlalchemy import (
    String, Integer, Float, Boolean, Text,
    DateTime, ForeignKey, Enum as SAEnum,
    UniqueConstraint, Index
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
import enum

from app.database.database import Base


# ================================================================
#  ENUM TURLARI — Jadval ustunlarida qat'iy qiymatlar uchun
# ================================================================

class UserRole(str, enum.Enum):
    """Foydalanuvchi roli"""
    ADMIN    = "admin"      # To'liq huquq
    OPERATOR = "operator"   # Zakazlarni boshqaradi
    MASTER   = "master"     # Faqat o'z zakazlarini ko'radi


class OrderStatus(str, enum.Enum):
    """Zakaz holati"""
    NEW         = "new"         # Yangi, hali qabul qilinmagan
    ACCEPTED    = "accepted"    # Qabul qilindi, usta tayinlandi
    DIAGNOSING  = "diagnosing"  # Diagnostika jarayonida
    WAITING     = "waiting"     # Zapchast kutilmoqda
    IN_REPAIR   = "in_repair"   # Ta'mirlanmoqda
    ON_THE_WAY  = "on_the_way"  # Usta vizitga yo'lda (geolokatsiya faol)
    DONE        = "done"        # Ta'mir tugadi, mijozga topshirilmagan
    DELIVERED   = "delivered"   # Mijozga topshirildi, to'lov qilindi
    CANCELLED   = "cancelled"   # Rad etildi / Bekor qilindi


class OrderSource(str, enum.Enum):
    """Zakaz qayerdan keldi"""
    WALK_IN   = "walk_in"    # Bevosita ustaxonaga keldi
    PHONE     = "phone"      # Telefon orqali
    TELEGRAM  = "telegram"   # Telegram bot orqali
    INSTAGRAM = "instagram"  # Instagram DM orqali
    OTHER     = "other"      # Boshqa


class PaymentMethod(str, enum.Enum):
    """To'lov usuli"""
    CASH     = "cash"      # Naqd pul
    CARD     = "card"      # Plastik karta
    TRANSFER = "transfer"  # Bank o'tkazmasi


class TransactionType(str, enum.Enum):
    """Moliyaviy operatsiya turi"""
    INCOME   = "income"   # Daromad (to'lov keldi)
    EXPENSE  = "expense"  # Xarajat (pul chiqdi)
    SALARY   = "salary"   # Ish haqi to'lovi
    REFUND   = "refund"   # Qaytarish


class WarehouseMovementType(str, enum.Enum):
    """Ombor harakati turi"""
    IN      = "in"      # Kirim — yangi zapchast keldi
    OUT     = "out"     # Chiqim — ta'mirda ishlatildi
    RETURN  = "return"  # Qaytarish — mijoz tomonidan


# ================================================================
#  1. USERS — Foydalanuvchilar jadvali (Admin, Operator, Usta)
# ================================================================

class User(Base):
    """
    Tizim foydalanuvchilari.
    Admin, Operator va Ustalar shu jadvalda saqlanadi.
    """
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    # --- Shaxsiy ma'lumotlar ---
    full_name: Mapped[str]           = mapped_column(String(100), nullable=False)
    phone: Mapped[Optional[str]]     = mapped_column(String(20), nullable=True)
    username: Mapped[str]            = mapped_column(String(50), unique=True, nullable=False)
    hashed_password: Mapped[str]     = mapped_column(String(255), nullable=False)

    # --- Rol va holat ---
    role: Mapped[UserRole]           = mapped_column(SAEnum(UserRole), default=UserRole.OPERATOR)
    is_active: Mapped[bool]          = mapped_column(Boolean, default=True)

    # --- Ish haqi va balans (faqat Usta/Operator uchun) ---
    # Bu ustaning shaxsiy balans hisob raqami:
    # har bir tugallangan zakaz uchun ulush qo'shiladi
    balance: Mapped[float]           = mapped_column(Float, default=0.0)
    salary_rate: Mapped[float]       = mapped_column(Float, default=0.0)
    # Har bir zakaz uchun foiz ulushi (masalan: 30.0 = 30%)
    commission_percent: Mapped[float] = mapped_column(Float, default=0.0)

    # --- Vaqt belgilari ---
    created_at: Mapped[datetime]     = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime]     = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    # --- Bog'liq ma'lumotlar ---
    orders_as_master: Mapped[list["Order"]]       = relationship("Order", foreign_keys="Order.master_id", back_populates="master")
    orders_as_operator: Mapped[list["Order"]]     = relationship("Order", foreign_keys="Order.operator_id", back_populates="operator")
    salary_payments: Mapped[list["SalaryPayment"]] = relationship("SalaryPayment", foreign_keys="SalaryPayment.worker_id", back_populates="worker")
    locations: Mapped[list["WorkerLocation"]]      = relationship("WorkerLocation", back_populates="worker", order_by="WorkerLocation.recorded_at.desc()")

    def __repr__(self) -> str:
        return f"<User id={self.id} username={self.username} role={self.role}>"


# ================================================================
#  2. CLIENTS — Mijozlar jadvali
# ================================================================

class Client(Base):
    """
    Ustaxona mijozlari.
    Telegram/Instagram orqali kelganda ham shu jadvalga yoziladi.
    """
    __tablename__ = "clients"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    # --- Shaxsiy ma'lumotlar ---
    full_name: Mapped[str]               = mapped_column(String(100), nullable=False)
    phone: Mapped[Optional[str]]         = mapped_column(String(20), nullable=True, index=True)
    phone_secondary: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    address: Mapped[Optional[str]]       = mapped_column(String(255), nullable=True)
    notes: Mapped[Optional[str]]         = mapped_column(Text, nullable=True)

    # --- Ijtimoiy tarmoq ma'lumotlari (integratsiyalar uchun) ---
    telegram_id: Mapped[Optional[str]]   = mapped_column(String(50), nullable=True, unique=True)
    telegram_username: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    instagram_id: Mapped[Optional[str]]  = mapped_column(String(50), nullable=True, unique=True)

    # --- Statistika ---
    total_orders: Mapped[int]            = mapped_column(Integer, default=0)
    total_spent: Mapped[float]           = mapped_column(Float, default=0.0)

    # --- Vaqt belgilari ---
    created_at: Mapped[datetime]         = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime]         = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    # --- Bog'liq ma'lumotlar ---
    orders: Mapped[list["Order"]]        = relationship("Order", back_populates="client")

    def __repr__(self) -> str:
        return f"<Client id={self.id} name={self.full_name} phone={self.phone}>"


# ================================================================
#  3. ORDERS — Zakazlar jadvali (CRM'ning yuragi)
# ================================================================

class Order(Base):
    """
    Har bir ta'mir zakazi.
    Bu jadval CRM tizimining asosiy jadvali hisoblanadi.
    """
    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    # --- Zakaz raqami (chiroyli, o'qish uchun qulay) ---
    # Masalan: TV-2024-0001
    order_number: Mapped[str]            = mapped_column(String(20), unique=True, nullable=False, index=True)

    # --- Mijoz (kim olib keldi) ---
    client_id: Mapped[int]               = mapped_column(Integer, ForeignKey("clients.id"), nullable=False)
    client: Mapped["Client"]             = relationship("Client", back_populates="orders")

    # --- Ishchilar ---
    operator_id: Mapped[Optional[int]]   = mapped_column(Integer, ForeignKey("users.id"), nullable=True)
    master_id: Mapped[Optional[int]]     = mapped_column(Integer, ForeignKey("users.id"), nullable=True)
    operator: Mapped[Optional["User"]]   = relationship("User", foreign_keys=[operator_id], back_populates="orders_as_operator")
    master: Mapped[Optional["User"]]     = relationship("User", foreign_keys=[master_id], back_populates="orders_as_master")

    # --- Televizor ma'lumotlari ---
    tv_brand: Mapped[Optional[str]]      = mapped_column(String(50), nullable=True)   # Samsung, LG, Sony...
    tv_model: Mapped[Optional[str]]      = mapped_column(String(100), nullable=True)  # UA55TU8000
    tv_diagonal: Mapped[Optional[str]]   = mapped_column(String(20), nullable=True)   # 55", 43"
    tv_serial_number: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)

    # --- Nosozlik tavsifi ---
    problem_description: Mapped[str]     = mapped_column(Text, nullable=False)
    # AI tahlilidan kelgan natija (Gemini)
    ai_diagnosis: Mapped[Optional[str]]  = mapped_column(Text, nullable=True)
    # Usta tomonidan yozilgan haqiqiy tashxis
    master_diagnosis: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    # Bajarilgan ishlar tavsifi
    work_done: Mapped[Optional[str]]     = mapped_column(Text, nullable=True)

    # --- Holat va manba ---
    status: Mapped[OrderStatus]          = mapped_column(SAEnum(OrderStatus), default=OrderStatus.NEW, index=True)
    source: Mapped[OrderSource]          = mapped_column(SAEnum(OrderSource), default=OrderSource.WALK_IN)

    # --- Moliyaviy ma'lumotlar ---
    estimated_price: Mapped[float]       = mapped_column(Float, default=0.0)  # Dastlabki narx
    final_price: Mapped[float]           = mapped_column(Float, default=0.0)  # Yakuniy narx
    parts_cost: Mapped[float]            = mapped_column(Float, default=0.0)  # Zapchastlar narxi
    is_paid: Mapped[bool]                = mapped_column(Boolean, default=False)
    payment_method: Mapped[Optional[PaymentMethod]] = mapped_column(SAEnum(PaymentMethod), nullable=True)

    # --- Ustaga hisoblangan komisyon ---
    master_commission: Mapped[float]     = mapped_column(Float, default=0.0)

    # --- Qabul qilish paytidagi rasm/hujjat ---
    # Fayllar yo'llari vergul bilan ajratilgan holda saqlanadi
    photos: Mapped[Optional[str]]        = mapped_column(Text, nullable=True)

    # --- Vaqt belgilari ---
    created_at: Mapped[datetime]         = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime]         = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())
    accepted_at: Mapped[Optional[datetime]]  = mapped_column(DateTime, nullable=True)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    delivered_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)

    # --- Arxiv (tugallangandan keyin) ---
    is_archived: Mapped[bool]            = mapped_column(Boolean, default=False)
    cancel_reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # --- Bog'liq ma'lumotlar ---
    status_history: Mapped[list["OrderStatusHistory"]]  = relationship("OrderStatusHistory", back_populates="order")
    used_parts: Mapped[list["OrderPart"]]               = relationship("OrderPart", back_populates="order")

    def __repr__(self) -> str:
        return f"<Order id={self.id} number={self.order_number} status={self.status}>"


# ================================================================
#  4. ORDER_STATUS_HISTORY — Zakaz holat tarixi
# ================================================================

class OrderStatusHistory(Base):
    """
    Har bir zakaz statusining o'zgarish tarixi.
    Kim, qachon, qaysi statusga o'zgartirganini saqlaydi.
    """
    __tablename__ = "order_status_history"

    id: Mapped[int]                  = mapped_column(Integer, primary_key=True, autoincrement=True)
    order_id: Mapped[int]            = mapped_column(Integer, ForeignKey("orders.id"), nullable=False)
    changed_by_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("users.id"), nullable=True)

    old_status: Mapped[Optional[OrderStatus]] = mapped_column(SAEnum(OrderStatus), nullable=True)
    new_status: Mapped[OrderStatus]           = mapped_column(SAEnum(OrderStatus), nullable=False)
    comment: Mapped[Optional[str]]            = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime]     = mapped_column(DateTime, server_default=func.now())

    # --- Bog'liq ma'lumotlar ---
    order: Mapped["Order"]           = relationship("Order", back_populates="status_history")
    changed_by: Mapped[Optional["User"]] = relationship("User")

    def __repr__(self) -> str:
        return f"<OrderStatusHistory order={self.order_id} {self.old_status}→{self.new_status}>"


# ================================================================
#  5. WAREHOUSE_ITEMS — Ombor: Zapchastlar va materiallar
# ================================================================

class WarehouseItem(Base):
    """
    Omborhona: har bir zapchast yoki material.
    Ekranlar, platalar, kondensatorlar, t-con va boshqalar.
    """
    __tablename__ = "warehouse_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    # --- Mahsulot ma'lumotlari ---
    name: Mapped[str]                  = mapped_column(String(200), nullable=False)
    article: Mapped[Optional[str]]     = mapped_column(String(100), nullable=True, unique=True)  # Katalog raqami
    category: Mapped[Optional[str]]    = mapped_column(String(100), nullable=True)  # Ekran, Plata, T-con...
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # --- Qaysi televiozorga mos keladi ---
    compatible_brands: Mapped[Optional[str]]  = mapped_column(String(255), nullable=True)  # Samsung, LG
    compatible_models: Mapped[Optional[str]]  = mapped_column(Text, nullable=True)

    # --- Miqdor va narx ---
    quantity: Mapped[int]              = mapped_column(Integer, default=0)
    min_quantity: Mapped[int]          = mapped_column(Integer, default=1)   # Minimal qoldiq (ogohlantirish uchun)
    unit: Mapped[str]                  = mapped_column(String(20), default="dona")

    purchase_price: Mapped[float]      = mapped_column(Float, default=0.0)   # Sotib olish narxi
    selling_price: Mapped[float]       = mapped_column(Float, default=0.0)   # Sotish narxi

    # --- Holat ---
    is_active: Mapped[bool]            = mapped_column(Boolean, default=True)

    # --- Vaqt belgilari ---
    created_at: Mapped[datetime]       = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime]       = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    # --- Bog'liq ma'lumotlar ---
    movements: Mapped[list["WarehouseMovement"]]  = relationship("WarehouseMovement", back_populates="item")
    order_parts: Mapped[list["OrderPart"]]        = relationship("OrderPart", back_populates="warehouse_item")

    @property
    def is_low_stock(self) -> bool:
        """Zaxira kam qolganini tekshiradi"""
        return self.quantity <= self.min_quantity

    def __repr__(self) -> str:
        return f"<WarehouseItem id={self.id} name={self.name} qty={self.quantity}>"


# ================================================================
#  6. WAREHOUSE_MOVEMENTS — Ombor harakati tarixi
# ================================================================

class WarehouseMovement(Base):
    """
    Omborga kirib-chiqqan barcha zapchastlar tarixi.
    Har bir kirim/chiqim shu yerda qayd etiladi.
    """
    __tablename__ = "warehouse_movements"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    item_id: Mapped[int]                  = mapped_column(Integer, ForeignKey("warehouse_items.id"), nullable=False)
    performed_by_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("users.id"), nullable=True)
    order_id: Mapped[Optional[int]]       = mapped_column(Integer, ForeignKey("orders.id"), nullable=True)

    movement_type: Mapped[WarehouseMovementType] = mapped_column(SAEnum(WarehouseMovementType), nullable=False)

    quantity: Mapped[int]                 = mapped_column(Integer, nullable=False)
    price_per_unit: Mapped[float]         = mapped_column(Float, default=0.0)
    total_price: Mapped[float]            = mapped_column(Float, default=0.0)

    notes: Mapped[Optional[str]]          = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime]          = mapped_column(DateTime, server_default=func.now())

    # --- Bog'liq ma'lumotlar ---
    item: Mapped["WarehouseItem"]         = relationship("WarehouseItem", back_populates="movements")
    performed_by: Mapped[Optional["User"]] = relationship("User")
    order: Mapped[Optional["Order"]]      = relationship("Order")

    def __repr__(self) -> str:
        return f"<WarehouseMovement item={self.item_id} type={self.movement_type} qty={self.quantity}>"


# ================================================================
#  7. ORDER_PARTS — Zakazda ishlatilgan zapchastlar
# ================================================================

class OrderPart(Base):
    """
    Har bir zakazda ishlatilgan zapchastlar.
    Zakaz va Ombor o'rtasidagi bog'lovchi jadval.
    """
    __tablename__ = "order_parts"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    order_id: Mapped[int]              = mapped_column(Integer, ForeignKey("orders.id"), nullable=False)
    warehouse_item_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("warehouse_items.id"), nullable=True)

    # Agar zapchast ombordan emas, tashqaridan olingan bo'lsa:
    custom_part_name: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)

    quantity: Mapped[int]              = mapped_column(Integer, default=1)
    price_per_unit: Mapped[float]      = mapped_column(Float, default=0.0)
    total_price: Mapped[float]         = mapped_column(Float, default=0.0)

    created_at: Mapped[datetime]       = mapped_column(DateTime, server_default=func.now())

    # --- Bog'liq ma'lumotlar ---
    order: Mapped["Order"]             = relationship("Order", back_populates="used_parts")
    warehouse_item: Mapped[Optional["WarehouseItem"]] = relationship("WarehouseItem", back_populates="order_parts")

    def __repr__(self) -> str:
        return f"<OrderPart order={self.order_id} item={self.warehouse_item_id} qty={self.quantity}>"


# ================================================================
#  8. FINANCE_TRANSACTIONS — Moliyaviy operatsiyalar (Kassa)
# ================================================================

class FinanceTransaction(Base):
    """
    Ustaxona kassasidagi barcha moliyaviy operatsiyalar.
    Kirim, chiqim, ish haqi — hammasi shu yerda.
    """
    __tablename__ = "finance_transactions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    transaction_type: Mapped[TransactionType] = mapped_column(SAEnum(TransactionType), nullable=False)

    amount: Mapped[float]              = mapped_column(Float, nullable=False)
    description: Mapped[str]          = mapped_column(String(255), nullable=False)
    notes: Mapped[Optional[str]]      = mapped_column(Text, nullable=True)

    # --- Kim amalga oshirdi ---
    performed_by_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("users.id"), nullable=True)
    performed_by: Mapped[Optional["User"]] = relationship("User")

    # --- Qaysi zakaz bilan bog'liq (agar bo'lsa) ---
    order_id: Mapped[Optional[int]]   = mapped_column(Integer, ForeignKey("orders.id"), nullable=True)
    order: Mapped[Optional["Order"]]  = relationship("Order")

    # --- To'lov usuli ---
    payment_method: Mapped[Optional[PaymentMethod]] = mapped_column(SAEnum(PaymentMethod), nullable=True)

    # --- Vaqt belgisi ---
    created_at: Mapped[datetime]      = mapped_column(DateTime, server_default=func.now())

    def __repr__(self) -> str:
        return f"<FinanceTransaction type={self.transaction_type} amount={self.amount}>"


# ================================================================
#  9. SALARY_PAYMENTS — Ishchilarga ish haqi to'lovlari
# ================================================================

class SalaryPayment(Base):
    """
    Ustalarga va operatorlarga qilingan ish haqi to'lovlari.
    Har bir to'lov qayd etiladi, balansdan ayiriladi.
    """
    __tablename__ = "salary_payments"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    worker_id: Mapped[int]            = mapped_column(Integer, ForeignKey("users.id"), nullable=False)
    worker: Mapped["User"]            = relationship("User", foreign_keys="SalaryPayment.worker_id", back_populates="salary_payments")

    amount: Mapped[float]             = mapped_column(Float, nullable=False)
    payment_method: Mapped[PaymentMethod] = mapped_column(SAEnum(PaymentMethod), default=PaymentMethod.CASH)

    notes: Mapped[Optional[str]]      = mapped_column(Text, nullable=True)

    # --- Kim to'ladi ---
    paid_by_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("users.id"), nullable=True)
    paid_by: Mapped[Optional["User"]] = relationship("User", foreign_keys="SalaryPayment.paid_by_id")

    created_at: Mapped[datetime]      = mapped_column(DateTime, server_default=func.now())

    def __repr__(self) -> str:
        return f"<SalaryPayment worker={self.worker_id} amount={self.amount}>"


# ================================================================
#  10. SHOP_SETTINGS — Ustaxona sozlamalari
# ================================================================

class ShopSettings(Base):
    """
    Ustaxona umumiy sozlamalari.
    Bitta qator bo'ladi (id=1).
    """
    __tablename__ = "shop_settings"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    shop_name: Mapped[str]             = mapped_column(String(200), default="TV Ta'mirlash Ustaxonasi")
    phone: Mapped[Optional[str]]       = mapped_column(String(20), nullable=True)
    address: Mapped[Optional[str]]     = mapped_column(String(255), nullable=True)

    # --- Moliyaviy sozlamalar ---
    # Ustaxonaning umumiy balansi (sof kassa)
    total_balance: Mapped[float]       = mapped_column(Float, default=0.0)
    # Xarajatlar fondi
    expense_balance: Mapped[float]     = mapped_column(Float, default=0.0)

    # --- Zakaz raqami uchun counter ---
    order_counter: Mapped[int]         = mapped_column(Integer, default=0)

    updated_at: Mapped[datetime]       = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    def __repr__(self) -> str:
        return f"<ShopSettings name={self.shop_name} balance={self.total_balance}>"


# ================================================================
#  11. WORKER_LOCATIONS — Ustalar geolokatsiya tarixi
# ================================================================

class WorkerLocation(Base):
    """
    Ustaning joylashuv yozuvlari.

    Arxitektura qarorlari:
      - ALOHIDA jadval: users jadvali shishmaydi
      - TARIX saqlanadi: faqat oxirgisi emas, butun vizit yo'nalishi
      - Har bir on_the_way statusidagi zakaz uchun koordinatalar yoziladi
      - Mobil ilova fonga shu jadvalga yozib turadi

    Misol oqim:
      1. Usta status → on_the_way     (vizit boshlandi)
      2. Mobil ilova har N sekundda koordinata jo'natadi  → bu jadval
      3. Usta status → in_repair/done (vizit tugadi)
      4. Admin xaritada ustaning butun yo'lini ko'radi
    """
    __tablename__ = "worker_locations"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    # --- Kim (usta) ---
    worker_id: Mapped[int]              = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False, index=True
    )
    worker: Mapped["User"]              = relationship("User", back_populates="locations")

    # --- Qaysi zakaz viziti uchun ---
    order_id: Mapped[Optional[int]]     = mapped_column(
        Integer, ForeignKey("orders.id", ondelete="SET NULL"),
        nullable=True, index=True
    )
    order: Mapped[Optional["Order"]]    = relationship("Order")

    # --- Koordinatalar (WGS84 standart) ---
    latitude: Mapped[float]             = mapped_column(
        Float, nullable=False,
        # Toshkent: ~41.3°, O'zbekiston: 37.2° – 45.6°
    )
    longitude: Mapped[float]            = mapped_column(
        Float, nullable=False,
        # Toshkent: ~69.2°, O'zbekiston: 56.0° – 73.1°
    )

    # --- Qo'shimcha GPS ma'lumotlari (ixtiyoriy) ---
    accuracy:  Mapped[Optional[float]]  = mapped_column(
        Float, nullable=True,
        # GPS aniqligi (metrda), masalan: 5.0 = ±5 metr
    )
    speed:     Mapped[Optional[float]]  = mapped_column(
        Float, nullable=True,
        # Tezlik (m/s), masalan: 8.3 = ~30 km/h
    )
    bearing:   Mapped[Optional[float]]  = mapped_column(
        Float, nullable=True,
        # Yo'nalish (gradus, 0=Shimol, 90=Sharq, 180=Janub, 270=G'arb)
    )
    altitude:  Mapped[Optional[float]]  = mapped_column(
        Float, nullable=True,
        # Balandlik (metrda dengiz sathidan)
    )

    # --- Manba va sifat ---
    # Koordinata qayerdan olingan: gps / network / passive
    location_provider: Mapped[Optional[str]] = mapped_column(
        String(20), nullable=True, default="gps"
    )
    # Batareya darajasi (%) — fon rejimini optimallashtirish uchun
    battery_level: Mapped[Optional[int]] = mapped_column(
        Integer, nullable=True
    )

    # --- Vaqt (mobil qurilma vaqti va server qabul vaqti) ---
    # device_time: qurilmaning mahalliy vaqti (oflayn rejimda ham to'g'ri bo'ladi)
    device_time: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    # recorded_at: server qabul qilgan vaqt (UTC) — asosiy vaqt damg'asi
    recorded_at: Mapped[datetime]           = mapped_column(
        DateTime, server_default=func.now(), nullable=False, index=True
    )

    def __repr__(self) -> str:
        return (
            f"<WorkerLocation worker={self.worker_id} "
            f"order={self.order_id} "
            f"({self.latitude:.4f}, {self.longitude:.4f}) "
            f"@ {self.recorded_at}>"
        )


# ================================================================
#  DATABASE INDEKSLARI — Tezlik uchun
# ================================================================
# Tez-tez qidiriladigan ustunlarga index qo'shamiz

Index("idx_orders_status",     Order.status)
Index("idx_orders_client",     Order.client_id)
Index("idx_orders_master",     Order.master_id)
Index("idx_orders_created",    Order.created_at)
Index("idx_orders_archived",   Order.is_archived)
Index("idx_clients_phone",     Client.phone)
Index("idx_finance_type",      FinanceTransaction.transaction_type)
Index("idx_finance_created",   FinanceTransaction.created_at)
Index("idx_warehouse_article", WarehouseItem.article)

# Geolokatsiya uchun kompozit indeks:
# "Ushbu ustaning, ushbu zakaz uchun, vaqt bo'yicha tartiblangan yozuvlari"
Index("idx_location_worker_order",   WorkerLocation.worker_id, WorkerLocation.order_id)
Index("idx_location_worker_time",    WorkerLocation.worker_id, WorkerLocation.recorded_at)
