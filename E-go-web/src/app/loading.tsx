import { Container } from "@/components/layout/container";
import { AppSkeleton } from "@/components/shared/app-skeleton";

/** The placeholder while a public page loads. */
export default function RootLoading() {
  return (
    <Container>
      <AppSkeleton />
    </Container>
  );
}
