import type { Metadata } from "next";

import { PaymentMethodsScreen } from "@/components/account/payment-methods-screen";
import { ROUTE_METADATA } from "@/lib/config/routes";

const meta = ROUTE_METADATA.paymentMethods;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function PaymentMethodsPage() {
  return <PaymentMethodsScreen />;
}
