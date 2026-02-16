command 2-

[

  {

    "schemaname": "public",

    "tablename": "cart_items",

    "policyname": "Users can delete their own cart items",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "DELETE",

    "using_expression": "(auth.uid() = user_id)",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "cart_items",

    "policyname": "Users can insert their own cart items",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "(auth.uid() = user_id)"

  },

  {

    "schemaname": "public",

    "tablename": "cart_items",

    "policyname": "Users can manage own cart",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "ALL",

    "using_expression": "(auth.uid() = user_id)",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "cart_items",

    "policyname": "Users can update their own cart items",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "UPDATE",

    "using_expression": "(auth.uid() = user_id)",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "cart_items",

    "policyname": "Users can view their own cart items",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "SELECT",

    "using_expression": "(auth.uid() = user_id)",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "category_notifications",

    "policyname": "Users can update their own notifications",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "UPDATE",

    "using_expression": "(user_id = auth.uid())",

    "with_check_expression": "(user_id = auth.uid())"

  },

  {

    "schemaname": "public",

    "tablename": "category_notifications",

    "policyname": "Users can view their own notifications",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "(user_id = auth.uid())",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "conversations",

    "policyname": "NGOs can create conversations",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "(ngo_id = auth.uid())"

  },

  {

    "schemaname": "public",

    "tablename": "conversations",

    "policyname": "Restaurants can create conversations",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "(restaurant_id = auth.uid())"

  },

  {

    "schemaname": "public",

    "tablename": "conversations",

    "policyname": "Users can view their own conversations",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "((ngo_id = auth.uid()) OR (restaurant_id = auth.uid()))",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "email_queue",

    "policyname": "Service role can manage email queue",

    "permissive": "PERMISSIVE",

    "roles": "{service_role}",

    "command": "ALL",

    "using_expression": "true",

    "with_check_expression": "true"

  },

  {

    "schemaname": "public",

    "tablename": "favorite_restaurants",

    "policyname": "Users can delete own favorite restaurants",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "DELETE",

    "using_expression": "(auth.uid() = user_id)",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "favorite_restaurants",

    "policyname": "Users can insert own favorite restaurants",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "(auth.uid() = user_id)"

  },

  {

    "schemaname": "public",

    "tablename": "favorite_restaurants",

    "policyname": "Users can view own favorite restaurants",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "SELECT",

    "using_expression": "(auth.uid() = user_id)",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "favorites",

    "policyname": "Users can delete favorites",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "DELETE",

    "using_expression": "(auth.uid() = user_id)",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "favorites",

    "policyname": "Users can insert favorites",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "(auth.uid() = user_id)"

  },

  {

    "schemaname": "public",

    "tablename": "favorites",

    "policyname": "Users can read favorites",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "SELECT",

    "using_expression": "(auth.uid() = user_id)",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "favorites",

    "policyname": "Users can update favorites",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "UPDATE",

    "using_expression": "(auth.uid() = user_id)",

    "with_check_expression": "(auth.uid() = user_id)"

  },

  {

    "schemaname": "public",

    "tablename": "free_meal_notifications",

    "policyname": "Restaurants can insert their own donations",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "(restaurant_id = auth.uid())"

  },

  {

    "schemaname": "public",

    "tablename": "free_meal_notifications",

    "policyname": "Restaurants can view their own donations",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "(restaurant_id = auth.uid())",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "free_meal_notifications",

    "policyname": "Users can claim free meals",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "UPDATE",

    "using_expression": "((claimed_by IS NULL) OR (claimed_by = auth.uid()))",

    "with_check_expression": "(claimed_by = auth.uid())"

  },

  {

    "schemaname": "public",

    "tablename": "free_meal_notifications",

    "policyname": "Users can view free meal notifications",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "true",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "free_meal_user_notifications",

    "policyname": "Users can update their own free meal notifications",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "UPDATE",

    "using_expression": "(user_id = auth.uid())",

    "with_check_expression": "(user_id = auth.uid())"

  },

  {

    "schemaname": "public",

    "tablename": "free_meal_user_notifications",

    "policyname": "Users can view their own free meal notifications",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "(user_id = auth.uid())",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "meal_reports",

    "policyname": "Restaurants can view reports about their meals",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "(restaurant_id = auth.uid())",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "meal_reports",

    "policyname": "Users can insert their own reports",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "(user_id = auth.uid())"

  },

  {

    "schemaname": "public",

    "tablename": "meal_reports",

    "policyname": "Users can view their own reports",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "(user_id = auth.uid())",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "meals",

    "policyname": "Anonymous can view active meals",

    "permissive": "PERMISSIVE",

    "roles": "{anon}",

    "command": "SELECT",

    "using_expression": "(((status = 'active'::text) OR (status IS NULL)) AND (quantity_available > 0) AND (expiry_date > now()))",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "meals",

    "policyname": "Public can view available meals",

    "permissive": "PERMISSIVE",

    "roles": "{anon,authenticated}",

    "command": "SELECT",

    "using_expression": "((quantity_available > 0) AND (expiry_date > now()))",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "meals",

    "policyname": "Restaurants can delete their own meals",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "DELETE",

    "using_expression": "(restaurant_id = auth.uid())",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "meals",

    "policyname": "Restaurants can insert their own meals",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "(restaurant_id = auth.uid())"

  },

  {

    "schemaname": "public",

    "tablename": "meals",

    "policyname": "Restaurants can update their own meals",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "UPDATE",

    "using_expression": "(restaurant_id = auth.uid())",

    "with_check_expression": "(restaurant_id = auth.uid())"

  },

  {

    "schemaname": "public",

    "tablename": "meals",

    "policyname": "Restaurants can view their own meals",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "(restaurant_id = auth.uid())",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "meals",

    "policyname": "Users can view active meals",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "(((status = 'active'::text) OR (status IS NULL)) AND (quantity_available > 0) AND (expiry_date > now()))",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "messages",

    "policyname": "Users can send messages in their conversations",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "((sender_id = auth.uid()) AND (EXISTS ( SELECT 1\n   FROM conversations\n  WHERE ((conversations.id = messages.conversation_id) AND ((conversations.ngo_id = auth.uid()) OR (conversations.restaurant_id = auth.uid()))))))"

  },

  {

    "schemaname": "public",

    "tablename": "messages",

    "policyname": "Users can update their own messages",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "UPDATE",

    "using_expression": "(EXISTS ( SELECT 1\n   FROM conversations\n  WHERE ((conversations.id = messages.conversation_id) AND ((conversations.ngo_id = auth.uid()) OR (conversations.restaurant_id = auth.uid())))))",

    "with_check_expression": "(EXISTS ( SELECT 1\n   FROM conversations\n  WHERE ((conversations.id = messages.conversation_id) AND ((conversations.ngo_id = auth.uid()) OR (conversations.restaurant_id = auth.uid())))))"

  },

  {

    "schemaname": "public",

    "tablename": "messages",

    "policyname": "Users can view messages in their conversations",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "(EXISTS ( SELECT 1\n   FROM conversations\n  WHERE ((conversations.id = messages.conversation_id) AND ((conversations.ngo_id = auth.uid()) OR (conversations.restaurant_id = auth.uid())))))",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "ngos",

    "policyname": "NGO owners can insert own details",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "(auth.uid() = profile_id)"

  },

  {

    "schemaname": "public",

    "tablename": "ngos",

    "policyname": "NGO owners can update own details",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "UPDATE",

    "using_expression": "(auth.uid() = profile_id)",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "ngos",

    "policyname": "NGO owners can update own record",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "UPDATE",

    "using_expression": "((auth.uid() = profile_id) OR is_admin())",

    "with_check_expression": "((auth.uid() = profile_id) OR is_admin())"

  },

  {

    "schemaname": "public",

    "tablename": "ngos",

    "policyname": "NGO owners can view own record",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "((auth.uid() = profile_id) OR is_admin())",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "ngos",

    "policyname": "NGOs can update their own profile",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "UPDATE",

    "using_expression": "(profile_id = auth.uid())",

    "with_check_expression": "(profile_id = auth.uid())"

  },

  {

    "schemaname": "public",

    "tablename": "ngos",

    "policyname": "NGOs can view their own profile",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "(profile_id = auth.uid())",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "ngos",

    "policyname": "NGOs: public browse approved",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "SELECT",

    "using_expression": "(EXISTS ( SELECT 1\n   FROM profiles p\n  WHERE ((p.id = ngos.profile_id) AND (p.approval_status = 'approved'::text))))",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "ngos",

    "policyname": "NGOs: select own",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "SELECT",

    "using_expression": "(auth.uid() = profile_id)",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "ngos",

    "policyname": "NGOs: update own",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "UPDATE",

    "using_expression": "(auth.uid() = profile_id)",

    "with_check_expression": "(auth.uid() = profile_id)"

  },

  {

    "schemaname": "public",

    "tablename": "ngos",

    "policyname": "Public can view NGOs",

    "permissive": "PERMISSIVE",

    "roles": "{anon,authenticated}",

    "command": "SELECT",

    "using_expression": "true",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "ngos",

    "policyname": "Public can view approved ngos",

    "permissive": "PERMISSIVE",

    "roles": "{anon,authenticated}",

    "command": "SELECT",

    "using_expression": "(EXISTS ( SELECT 1\n   FROM profiles p\n  WHERE ((p.id = ngos.profile_id) AND (p.approval_status = 'approved'::text))))",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "ngos",

    "policyname": "Public can view ngos",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "SELECT",

    "using_expression": "true",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "ngos",

    "policyname": "Service role can insert ngos",

    "permissive": "PERMISSIVE",

    "roles": "{service_role}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "true"

  },

  {

    "schemaname": "public",

    "tablename": "ngos",

    "policyname": "System can insert ngos",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "true"

  },

  {

    "schemaname": "public",

    "tablename": "ngos",

    "policyname": "Users can update own ngo",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "UPDATE",

    "using_expression": "(auth.uid() = profile_id)",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "ngos",

    "policyname": "Users can view own ngo",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "SELECT",

    "using_expression": "(auth.uid() = profile_id)",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "order_items",

    "policyname": "Authenticated users can create order items",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "(EXISTS ( SELECT 1\n   FROM orders o\n  WHERE ((o.id = order_items.order_id) AND (o.user_id = auth.uid()))))"

  },

  {

    "schemaname": "public",

    "tablename": "order_items",

    "policyname": "NGOs can view their order items",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "SELECT",

    "using_expression": "(EXISTS ( SELECT 1\n   FROM orders o\n  WHERE ((o.id = order_items.order_id) AND (o.ngo_id = auth.uid()))))",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "order_items",

    "policyname": "Restaurants can view their order items",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "(order_id IN ( SELECT orders.id\n   FROM orders\n  WHERE (orders.restaurant_id = auth.uid())))",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "order_items",

    "policyname": "Users can insert their order items",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "(EXISTS ( SELECT 1\n   FROM orders\n  WHERE ((orders.id = order_items.order_id) AND (orders.user_id = auth.uid()))))"

  },

  {

    "schemaname": "public",

    "tablename": "order_items",

    "policyname": "Users can view their order items",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "(order_id IN ( SELECT orders.id\n   FROM orders\n  WHERE (orders.user_id = auth.uid())))",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "order_status_history",

    "policyname": "Allow status history inserts",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "true"

  },

  {

    "schemaname": "public",

    "tablename": "order_status_history",

    "policyname": "Restaurants can insert status history for their orders",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "(EXISTS ( SELECT 1\n   FROM orders\n  WHERE ((orders.id = order_status_history.order_id) AND (orders.restaurant_id = auth.uid()))))"

  },

  {

    "schemaname": "public",

    "tablename": "order_status_history",

    "policyname": "Restaurants can view their order history",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "(EXISTS ( SELECT 1\n   FROM orders\n  WHERE ((orders.id = order_status_history.order_id) AND (orders.restaurant_id = auth.uid()))))",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "order_status_history",

    "policyname": "Users can view their order history",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "(EXISTS ( SELECT 1\n   FROM orders\n  WHERE ((orders.id = order_status_history.order_id) AND (orders.user_id = auth.uid()))))",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "orders",

    "policyname": "NGOs can view their orders",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "(ngo_id = auth.uid())",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "orders",

    "policyname": "Restaurants can update their orders",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "UPDATE",

    "using_expression": "(restaurant_id = auth.uid())",

    "with_check_expression": "(restaurant_id = auth.uid())"

  },

  {

    "schemaname": "public",

    "tablename": "orders",

    "policyname": "Restaurants can view their orders",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "(restaurant_id = auth.uid())",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "orders",

    "policyname": "Users can create orders",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "(auth.uid() = user_id)"

  },

  {

    "schemaname": "public",

    "tablename": "orders",

    "policyname": "Users can insert their own orders",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "(user_id = auth.uid())"

  },

  {

    "schemaname": "public",

    "tablename": "orders",

    "policyname": "Users can update their own orders",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "UPDATE",

    "using_expression": "(user_id = auth.uid())",

    "with_check_expression": "(user_id = auth.uid())"

  },

  {

    "schemaname": "public",

    "tablename": "orders",

    "policyname": "Users can view their orders",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "(user_id = auth.uid())",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "payments",

    "policyname": "Users can view own payments",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "SELECT",

    "using_expression": "(EXISTS ( SELECT 1\n   FROM orders\n  WHERE ((orders.id = payments.order_id) AND (orders.user_id = auth.uid()))))",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "profiles",

    "policyname": "Public can view approved profiles",

    "permissive": "PERMISSIVE",

    "roles": "{anon,authenticated}",

    "command": "SELECT",

    "using_expression": "(approval_status = 'approved'::text)",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "profiles",

    "policyname": "Service role can insert profiles",

    "permissive": "PERMISSIVE",

    "roles": "{service_role}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "true"

  },

  {

    "schemaname": "public",

    "tablename": "profiles",

    "policyname": "Users can insert their profile",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "(id = auth.uid())"

  },

  {

    "schemaname": "public",

    "tablename": "profiles",

    "policyname": "Users can update their profile",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "UPDATE",

    "using_expression": "((id = auth.uid()) OR is_admin())",

    "with_check_expression": "((id = auth.uid()) OR is_admin())"

  },

  {

    "schemaname": "public",

    "tablename": "profiles",

    "policyname": "Users can view their profile",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "((id = auth.uid()) OR is_admin())",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "restaurants",

    "policyname": "Public can view approved restaurants",

    "permissive": "PERMISSIVE",

    "roles": "{anon,authenticated}",

    "command": "SELECT",

    "using_expression": "(EXISTS ( SELECT 1\n   FROM profiles p\n  WHERE ((p.id = restaurants.profile_id) AND (p.approval_status = 'approved'::text))))",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "restaurants",

    "policyname": "Public can view restaurants",

    "permissive": "PERMISSIVE",

    "roles": "{anon,authenticated}",

    "command": "SELECT",

    "using_expression": "true",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "restaurants",

    "policyname": "Restaurant owners can insert own details",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "(auth.uid() = profile_id)"

  },

  {

    "schemaname": "public",

    "tablename": "restaurants",

    "policyname": "Restaurant owners can update own details",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "UPDATE",

    "using_expression": "(auth.uid() = profile_id)",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "restaurants",

    "policyname": "Restaurant owners can update own record",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "UPDATE",

    "using_expression": "((auth.uid() = profile_id) OR is_admin())",

    "with_check_expression": "((auth.uid() = profile_id) OR is_admin())"

  },

  {

    "schemaname": "public",

    "tablename": "restaurants",

    "policyname": "Restaurant owners can view own record",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "((auth.uid() = profile_id) OR is_admin())",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "restaurants",

    "policyname": "Restaurants can update their own profile",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "UPDATE",

    "using_expression": "(profile_id = auth.uid())",

    "with_check_expression": "(profile_id = auth.uid())"

  },

  {

    "schemaname": "public",

    "tablename": "restaurants",

    "policyname": "Restaurants can view their own profile",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "(profile_id = auth.uid())",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "restaurants",

    "policyname": "Restaurants: public browse approved",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "SELECT",

    "using_expression": "(EXISTS ( SELECT 1\n   FROM profiles p\n  WHERE ((p.id = restaurants.profile_id) AND (p.approval_status = 'approved'::text))))",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "restaurants",

    "policyname": "Restaurants: select own",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "SELECT",

    "using_expression": "(auth.uid() = profile_id)",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "restaurants",

    "policyname": "Restaurants: update own",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "UPDATE",

    "using_expression": "(auth.uid() = profile_id)",

    "with_check_expression": "(auth.uid() = profile_id)"

  },

  {

    "schemaname": "public",

    "tablename": "restaurants",

    "policyname": "Service role can insert restaurants",

    "permissive": "PERMISSIVE",

    "roles": "{service_role}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "true"

  },

  {

    "schemaname": "public",

    "tablename": "restaurants",

    "policyname": "System can insert restaurants",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "true"

  },

  {

    "schemaname": "public",

    "tablename": "restaurants",

    "policyname": "Users can update own restaurant",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "UPDATE",

    "using_expression": "(auth.uid() = profile_id)",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "restaurants",

    "policyname": "Users can view own restaurant",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "SELECT",

    "using_expression": "(auth.uid() = profile_id)",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "rush_hours",

    "policyname": "Public can view active rush hours",

    "permissive": "PERMISSIVE",

    "roles": "{anon,authenticated}",

    "command": "SELECT",

    "using_expression": "(is_active = true)",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "rush_hours",

    "policyname": "Public can view rush hours",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "SELECT",

    "using_expression": "true",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "rush_hours",

    "policyname": "Restaurant owners can manage rush hours",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "ALL",

    "using_expression": "(auth.uid() = restaurant_id)",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "rush_hours",

    "policyname": "Restaurants can delete their own rush hours",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "DELETE",

    "using_expression": "(restaurant_id = auth.uid())",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "rush_hours",

    "policyname": "Restaurants can insert their own rush hours",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "(restaurant_id = auth.uid())"

  },

  {

    "schemaname": "public",

    "tablename": "rush_hours",

    "policyname": "Restaurants can update their own rush hours",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "UPDATE",

    "using_expression": "(restaurant_id = auth.uid())",

    "with_check_expression": "(restaurant_id = auth.uid())"

  },

  {

    "schemaname": "public",

    "tablename": "rush_hours",

    "policyname": "Restaurants can view their own rush hours",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "(restaurant_id = auth.uid())",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "user_addresses",

    "policyname": "Users can delete own addresses",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "DELETE",

    "using_expression": "(auth.uid() = user_id)",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "user_addresses",

    "policyname": "Users can delete their own addresses",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "DELETE",

    "using_expression": "(user_id = auth.uid())",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "user_addresses",

    "policyname": "Users can insert own addresses",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "(auth.uid() = user_id)"

  },

  {

    "schemaname": "public",

    "tablename": "user_addresses",

    "policyname": "Users can insert their own addresses",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "(user_id = auth.uid())"

  },

  {

    "schemaname": "public",

    "tablename": "user_addresses",

    "policyname": "Users can update own addresses",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "UPDATE",

    "using_expression": "(auth.uid() = user_id)",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "user_addresses",

    "policyname": "Users can update their own addresses",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "UPDATE",

    "using_expression": "(user_id = auth.uid())",

    "with_check_expression": "(user_id = auth.uid())"

  },

  {

    "schemaname": "public",

    "tablename": "user_addresses",

    "policyname": "Users can view own addresses",

    "permissive": "PERMISSIVE",

    "roles": "{public}",

    "command": "SELECT",

    "using_expression": "(auth.uid() = user_id)",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "user_addresses",

    "policyname": "Users can view their own addresses",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "(user_id = auth.uid())",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "user_category_preferences",

    "policyname": "Users can delete their own category preferences",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "DELETE",

    "using_expression": "(user_id = auth.uid())",

    "with_check_expression": null

  },

  {

    "schemaname": "public",

    "tablename": "user_category_preferences",

    "policyname": "Users can insert their own category preferences",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "INSERT",

    "using_expression": null,

    "with_check_expression": "(user_id = auth.uid())"

  },

  {

    "schemaname": "public",

    "tablename": "user_category_preferences",

    "policyname": "Users can update their own category preferences",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "UPDATE",

    "using_expression": "(user_id = auth.uid())",

    "with_check_expression": "(user_id = auth.uid())"

  },

  {

    "schemaname": "public",

    "tablename": "user_category_preferences",

    "policyname": "Users can view their own category preferences",

    "permissive": "PERMISSIVE",

    "roles": "{authenticated}",

    "command": "SELECT",

    "using_expression": "(user_id = auth.uid())",

    "with_check_expression": null

  }

]



command 3 -

[

  {

    "Table": "cart_items",

    "Policy Name": "Users can manage own cart",

    "Command": "ALL",

    "Using Expression": "USING: (auth.uid() = user_id)",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "cart_items",

    "Policy Name": "Users can delete their own cart items",

    "Command": "DELETE",

    "Using Expression": "USING: (auth.uid() = user_id)",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "cart_items",

    "Policy Name": "Users can insert their own cart items",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: (auth.uid() = user_id)"

  },

  {

    "Table": "cart_items",

    "Policy Name": "Users can view their own cart items",

    "Command": "SELECT",

    "Using Expression": "USING: (auth.uid() = user_id)",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "cart_items",

    "Policy Name": "Users can update their own cart items",

    "Command": "UPDATE",

    "Using Expression": "USING: (auth.uid() = user_id)",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "category_notifications",

    "Policy Name": "Users can view their own notifications",

    "Command": "SELECT",

    "Using Expression": "USING: (user_id = auth.uid())",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "category_notifications",

    "Policy Name": "Users can update their own notifications",

    "Command": "UPDATE",

    "Using Expression": "USING: (user_id = auth.uid())",

    "With Check Expression": "WITH CHECK: (user_id = auth.uid())"

  },

  {

    "Table": "conversations",

    "Policy Name": "NGOs can create conversations",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: (ngo_id = auth.uid())"

  },

  {

    "Table": "conversations",

    "Policy Name": "Restaurants can create conversations",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: (restaurant_id = auth.uid())"

  },

  {

    "Table": "conversations",

    "Policy Name": "Users can view their own conversations",

    "Command": "SELECT",

    "Using Expression": "USING: ((ngo_id = auth.uid()) OR (restaurant_id = auth.uid()))",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "email_queue",

    "Policy Name": "Service role can manage email queue",

    "Command": "ALL",

    "Using Expression": "USING: true",

    "With Check Expression": "WITH CHECK: true"

  },

  {

    "Table": "favorite_restaurants",

    "Policy Name": "Users can delete own favorite restaurants",

    "Command": "DELETE",

    "Using Expression": "USING: (auth.uid() = user_id)",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "favorite_restaurants",

    "Policy Name": "Users can insert own favorite restaurants",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: (auth.uid() = user_id)"

  },

  {

    "Table": "favorite_restaurants",

    "Policy Name": "Users can view own favorite restaurants",

    "Command": "SELECT",

    "Using Expression": "USING: (auth.uid() = user_id)",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "favorites",

    "Policy Name": "Users can delete favorites",

    "Command": "DELETE",

    "Using Expression": "USING: (auth.uid() = user_id)",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "favorites",

    "Policy Name": "Users can insert favorites",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: (auth.uid() = user_id)"

  },

  {

    "Table": "favorites",

    "Policy Name": "Users can read favorites",

    "Command": "SELECT",

    "Using Expression": "USING: (auth.uid() = user_id)",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "favorites",

    "Policy Name": "Users can update favorites",

    "Command": "UPDATE",

    "Using Expression": "USING: (auth.uid() = user_id)",

    "With Check Expression": "WITH CHECK: (auth.uid() = user_id)"

  },

  {

    "Table": "free_meal_notifications",

    "Policy Name": "Restaurants can insert their own donations",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: (restaurant_id = auth.uid())"

  },

  {

    "Table": "free_meal_notifications",

    "Policy Name": "Restaurants can view their own donations",

    "Command": "SELECT",

    "Using Expression": "USING: (restaurant_id = auth.uid())",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "free_meal_notifications",

    "Policy Name": "Users can view free meal notifications",

    "Command": "SELECT",

    "Using Expression": "USING: true",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "free_meal_notifications",

    "Policy Name": "Users can claim free meals",

    "Command": "UPDATE",

    "Using Expression": "USING: ((claimed_by IS NULL) OR (claimed_by = auth.uid()))",

    "With Check Expression": "WITH CHECK: (claimed_by = auth.uid())"

  },

  {

    "Table": "free_meal_user_notifications",

    "Policy Name": "Users can view their own free meal notifications",

    "Command": "SELECT",

    "Using Expression": "USING: (user_id = auth.uid())",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "free_meal_user_notifications",

    "Policy Name": "Users can update their own free meal notifications",

    "Command": "UPDATE",

    "Using Expression": "USING: (user_id = auth.uid())",

    "With Check Expression": "WITH CHECK: (user_id = auth.uid())"

  },

  {

    "Table": "meal_reports",

    "Policy Name": "Users can insert their own reports",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: (user_id = auth.uid())"

  },

  {

    "Table": "meal_reports",

    "Policy Name": "Restaurants can view reports about their meals",

    "Command": "SELECT",

    "Using Expression": "USING: (restaurant_id = auth.uid())",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "meal_reports",

    "Policy Name": "Users can view their own reports",

    "Command": "SELECT",

    "Using Expression": "USING: (user_id = auth.uid())",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "meals",

    "Policy Name": "Restaurants can delete their own meals",

    "Command": "DELETE",

    "Using Expression": "USING: (restaurant_id = auth.uid())",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "meals",

    "Policy Name": "Restaurants can insert their own meals",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: (restaurant_id = auth.uid())"

  },

  {

    "Table": "meals",

    "Policy Name": "Anonymous can view active meals",

    "Command": "SELECT",

    "Using Expression": "USING: (((status = 'active'::text) OR (status IS NULL)) AND (quantity_available > 0) AND (expiry_date > now()))",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "meals",

    "Policy Name": "Public can view available meals",

    "Command": "SELECT",

    "Using Expression": "USING: ((quantity_available > 0) AND (expiry_date > now()))",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "meals",

    "Policy Name": "Restaurants can view their own meals",

    "Command": "SELECT",

    "Using Expression": "USING: (restaurant_id = auth.uid())",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "meals",

    "Policy Name": "Users can view active meals",

    "Command": "SELECT",

    "Using Expression": "USING: (((status = 'active'::text) OR (status IS NULL)) AND (quantity_available > 0) AND (expiry_date > now()))",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "meals",

    "Policy Name": "Restaurants can update their own meals",

    "Command": "UPDATE",

    "Using Expression": "USING: (restaurant_id = auth.uid())",

    "With Check Expression": "WITH CHECK: (restaurant_id = auth.uid())"

  },

  {

    "Table": "messages",

    "Policy Name": "Users can send messages in their conversations",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: ((sender_id = auth.uid()) AND (EXISTS ( SELECT 1\n   FROM conversations\n  WHERE ((conversations.id = messages.conversation_id) AND ((conversations.ngo_id = auth.uid()) OR (conversations.restaurant_id = auth.uid()))))))"

  },

  {

    "Table": "messages",

    "Policy Name": "Users can view messages in their conversations",

    "Command": "SELECT",

    "Using Expression": "USING: (EXISTS ( SELECT 1\n   FROM conversations\n  WHERE ((conversations.id = messages.conversation_id) AND ((conversations.ngo_id = auth.uid()) OR (conversations.restaurant_id = auth.uid())))))",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "messages",

    "Policy Name": "Users can update their own messages",

    "Command": "UPDATE",

    "Using Expression": "USING: (EXISTS ( SELECT 1\n   FROM conversations\n  WHERE ((conversations.id = messages.conversation_id) AND ((conversations.ngo_id = auth.uid()) OR (conversations.restaurant_id = auth.uid())))))",

    "With Check Expression": "WITH CHECK: (EXISTS ( SELECT 1\n   FROM conversations\n  WHERE ((conversations.id = messages.conversation_id) AND ((conversations.ngo_id = auth.uid()) OR (conversations.restaurant_id = auth.uid())))))"

  },

  {

    "Table": "ngos",

    "Policy Name": "NGO owners can insert own details",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: (auth.uid() = profile_id)"

  },

  {

    "Table": "ngos",

    "Policy Name": "Service role can insert ngos",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: true"

  },

  {

    "Table": "ngos",

    "Policy Name": "System can insert ngos",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: true"

  },

  {

    "Table": "ngos",

    "Policy Name": "NGO owners can view own record",

    "Command": "SELECT",

    "Using Expression": "USING: ((auth.uid() = profile_id) OR is_admin())",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "ngos",

    "Policy Name": "NGOs can view their own profile",

    "Command": "SELECT",

    "Using Expression": "USING: (profile_id = auth.uid())",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "ngos",

    "Policy Name": "NGOs: public browse approved",

    "Command": "SELECT",

    "Using Expression": "USING: (EXISTS ( SELECT 1\n   FROM profiles p\n  WHERE ((p.id = ngos.profile_id) AND (p.approval_status = 'approved'::text))))",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "ngos",

    "Policy Name": "NGOs: select own",

    "Command": "SELECT",

    "Using Expression": "USING: (auth.uid() = profile_id)",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "ngos",

    "Policy Name": "Public can view NGOs",

    "Command": "SELECT",

    "Using Expression": "USING: true",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "ngos",

    "Policy Name": "Public can view approved ngos",

    "Command": "SELECT",

    "Using Expression": "USING: (EXISTS ( SELECT 1\n   FROM profiles p\n  WHERE ((p.id = ngos.profile_id) AND (p.approval_status = 'approved'::text))))",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "ngos",

    "Policy Name": "Public can view ngos",

    "Command": "SELECT",

    "Using Expression": "USING: true",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "ngos",

    "Policy Name": "Users can view own ngo",

    "Command": "SELECT",

    "Using Expression": "USING: (auth.uid() = profile_id)",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "ngos",

    "Policy Name": "NGO owners can update own details",

    "Command": "UPDATE",

    "Using Expression": "USING: (auth.uid() = profile_id)",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "ngos",

    "Policy Name": "NGO owners can update own record",

    "Command": "UPDATE",

    "Using Expression": "USING: ((auth.uid() = profile_id) OR is_admin())",

    "With Check Expression": "WITH CHECK: ((auth.uid() = profile_id) OR is_admin())"

  },

  {

    "Table": "ngos",

    "Policy Name": "NGOs can update their own profile",

    "Command": "UPDATE",

    "Using Expression": "USING: (profile_id = auth.uid())",

    "With Check Expression": "WITH CHECK: (profile_id = auth.uid())"

  },

  {

    "Table": "ngos",

    "Policy Name": "NGOs: update own",

    "Command": "UPDATE",

    "Using Expression": "USING: (auth.uid() = profile_id)",

    "With Check Expression": "WITH CHECK: (auth.uid() = profile_id)"

  },

  {

    "Table": "ngos",

    "Policy Name": "Users can update own ngo",

    "Command": "UPDATE",

    "Using Expression": "USING: (auth.uid() = profile_id)",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "order_items",

    "Policy Name": "Authenticated users can create order items",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: (EXISTS ( SELECT 1\n   FROM orders o\n  WHERE ((o.id = order_items.order_id) AND (o.user_id = auth.uid()))))"

  },

  {

    "Table": "order_items",

    "Policy Name": "Users can insert their order items",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: (EXISTS ( SELECT 1\n   FROM orders\n  WHERE ((orders.id = order_items.order_id) AND (orders.user_id = auth.uid()))))"

  },

  {

    "Table": "order_items",

    "Policy Name": "NGOs can view their order items",

    "Command": "SELECT",

    "Using Expression": "USING: (EXISTS ( SELECT 1\n   FROM orders o\n  WHERE ((o.id = order_items.order_id) AND (o.ngo_id = auth.uid()))))",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "order_items",

    "Policy Name": "Restaurants can view their order items",

    "Command": "SELECT",

    "Using Expression": "USING: (order_id IN ( SELECT orders.id\n   FROM orders\n  WHERE (orders.restaurant_id = auth.uid())))",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "order_items",

    "Policy Name": "Users can view their order items",

    "Command": "SELECT",

    "Using Expression": "USING: (order_id IN ( SELECT orders.id\n   FROM orders\n  WHERE (orders.user_id = auth.uid())))",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "order_status_history",

    "Policy Name": "Allow status history inserts",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: true"

  },

  {

    "Table": "order_status_history",

    "Policy Name": "Restaurants can insert status history for their orders",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: (EXISTS ( SELECT 1\n   FROM orders\n  WHERE ((orders.id = order_status_history.order_id) AND (orders.restaurant_id = auth.uid()))))"

  },

  {

    "Table": "order_status_history",

    "Policy Name": "Restaurants can view their order history",

    "Command": "SELECT",

    "Using Expression": "USING: (EXISTS ( SELECT 1\n   FROM orders\n  WHERE ((orders.id = order_status_history.order_id) AND (orders.restaurant_id = auth.uid()))))",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "order_status_history",

    "Policy Name": "Users can view their order history",

    "Command": "SELECT",

    "Using Expression": "USING: (EXISTS ( SELECT 1\n   FROM orders\n  WHERE ((orders.id = order_status_history.order_id) AND (orders.user_id = auth.uid()))))",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "orders",

    "Policy Name": "Users can create orders",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: (auth.uid() = user_id)"

  },

  {

    "Table": "orders",

    "Policy Name": "Users can insert their own orders",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: (user_id = auth.uid())"

  },

  {

    "Table": "orders",

    "Policy Name": "NGOs can view their orders",

    "Command": "SELECT",

    "Using Expression": "USING: (ngo_id = auth.uid())",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "orders",

    "Policy Name": "Restaurants can view their orders",

    "Command": "SELECT",

    "Using Expression": "USING: (restaurant_id = auth.uid())",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "orders",

    "Policy Name": "Users can view their orders",

    "Command": "SELECT",

    "Using Expression": "USING: (user_id = auth.uid())",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "orders",

    "Policy Name": "Restaurants can update their orders",

    "Command": "UPDATE",

    "Using Expression": "USING: (restaurant_id = auth.uid())",

    "With Check Expression": "WITH CHECK: (restaurant_id = auth.uid())"

  },

  {

    "Table": "orders",

    "Policy Name": "Users can update their own orders",

    "Command": "UPDATE",

    "Using Expression": "USING: (user_id = auth.uid())",

    "With Check Expression": "WITH CHECK: (user_id = auth.uid())"

  },

  {

    "Table": "payments",

    "Policy Name": "Users can view own payments",

    "Command": "SELECT",

    "Using Expression": "USING: (EXISTS ( SELECT 1\n   FROM orders\n  WHERE ((orders.id = payments.order_id) AND (orders.user_id = auth.uid()))))",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "profiles",

    "Policy Name": "Service role can insert profiles",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: true"

  },

  {

    "Table": "profiles",

    "Policy Name": "Users can insert their profile",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: (id = auth.uid())"

  },

  {

    "Table": "profiles",

    "Policy Name": "Public can view approved profiles",

    "Command": "SELECT",

    "Using Expression": "USING: (approval_status = 'approved'::text)",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "profiles",

    "Policy Name": "Users can view their profile",

    "Command": "SELECT",

    "Using Expression": "USING: ((id = auth.uid()) OR is_admin())",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "profiles",

    "Policy Name": "Users can update their profile",

    "Command": "UPDATE",

    "Using Expression": "USING: ((id = auth.uid()) OR is_admin())",

    "With Check Expression": "WITH CHECK: ((id = auth.uid()) OR is_admin())"

  },

  {

    "Table": "restaurants",

    "Policy Name": "Restaurant owners can insert own details",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: (auth.uid() = profile_id)"

  },

  {

    "Table": "restaurants",

    "Policy Name": "Service role can insert restaurants",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: true"

  },

  {

    "Table": "restaurants",

    "Policy Name": "System can insert restaurants",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: true"

  },

  {

    "Table": "restaurants",

    "Policy Name": "Public can view approved restaurants",

    "Command": "SELECT",

    "Using Expression": "USING: (EXISTS ( SELECT 1\n   FROM profiles p\n  WHERE ((p.id = restaurants.profile_id) AND (p.approval_status = 'approved'::text))))",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "restaurants",

    "Policy Name": "Public can view restaurants",

    "Command": "SELECT",

    "Using Expression": "USING: true",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "restaurants",

    "Policy Name": "Restaurant owners can view own record",

    "Command": "SELECT",

    "Using Expression": "USING: ((auth.uid() = profile_id) OR is_admin())",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "restaurants",

    "Policy Name": "Restaurants can view their own profile",

    "Command": "SELECT",

    "Using Expression": "USING: (profile_id = auth.uid())",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "restaurants",

    "Policy Name": "Restaurants: public browse approved",

    "Command": "SELECT",

    "Using Expression": "USING: (EXISTS ( SELECT 1\n   FROM profiles p\n  WHERE ((p.id = restaurants.profile_id) AND (p.approval_status = 'approved'::text))))",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "restaurants",

    "Policy Name": "Restaurants: select own",

    "Command": "SELECT",

    "Using Expression": "USING: (auth.uid() = profile_id)",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "restaurants",

    "Policy Name": "Users can view own restaurant",

    "Command": "SELECT",

    "Using Expression": "USING: (auth.uid() = profile_id)",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "restaurants",

    "Policy Name": "Restaurant owners can update own details",

    "Command": "UPDATE",

    "Using Expression": "USING: (auth.uid() = profile_id)",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "restaurants",

    "Policy Name": "Restaurant owners can update own record",

    "Command": "UPDATE",

    "Using Expression": "USING: ((auth.uid() = profile_id) OR is_admin())",

    "With Check Expression": "WITH CHECK: ((auth.uid() = profile_id) OR is_admin())"

  },

  {

    "Table": "restaurants",

    "Policy Name": "Restaurants can update their own profile",

    "Command": "UPDATE",

    "Using Expression": "USING: (profile_id = auth.uid())",

    "With Check Expression": "WITH CHECK: (profile_id = auth.uid())"

  },

  {

    "Table": "restaurants",

    "Policy Name": "Restaurants: update own",

    "Command": "UPDATE",

    "Using Expression": "USING: (auth.uid() = profile_id)",

    "With Check Expression": "WITH CHECK: (auth.uid() = profile_id)"

  },

  {

    "Table": "restaurants",

    "Policy Name": "Users can update own restaurant",

    "Command": "UPDATE",

    "Using Expression": "USING: (auth.uid() = profile_id)",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "rush_hours",

    "Policy Name": "Restaurant owners can manage rush hours",

    "Command": "ALL",

    "Using Expression": "USING: (auth.uid() = restaurant_id)",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "rush_hours",

    "Policy Name": "Restaurants can delete their own rush hours",

    "Command": "DELETE",

    "Using Expression": "USING: (restaurant_id = auth.uid())",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "rush_hours",

    "Policy Name": "Restaurants can insert their own rush hours",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: (restaurant_id = auth.uid())"

  },

  {

    "Table": "rush_hours",

    "Policy Name": "Public can view active rush hours",

    "Command": "SELECT",

    "Using Expression": "USING: (is_active = true)",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "rush_hours",

    "Policy Name": "Public can view rush hours",

    "Command": "SELECT",

    "Using Expression": "USING: true",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "rush_hours",

    "Policy Name": "Restaurants can view their own rush hours",

    "Command": "SELECT",

    "Using Expression": "USING: (restaurant_id = auth.uid())",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "rush_hours",

    "Policy Name": "Restaurants can update their own rush hours",

    "Command": "UPDATE",

    "Using Expression": "USING: (restaurant_id = auth.uid())",

    "With Check Expression": "WITH CHECK: (restaurant_id = auth.uid())"

  },

  {

    "Table": "user_addresses",

    "Policy Name": "Users can delete own addresses",

    "Command": "DELETE",

    "Using Expression": "USING: (auth.uid() = user_id)",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "user_addresses",

    "Policy Name": "Users can delete their own addresses",

    "Command": "DELETE",

    "Using Expression": "USING: (user_id = auth.uid())",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "user_addresses",

    "Policy Name": "Users can insert own addresses",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: (auth.uid() = user_id)"

  },

  {

    "Table": "user_addresses",

    "Policy Name": "Users can insert their own addresses",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: (user_id = auth.uid())"

  },

  {

    "Table": "user_addresses",

    "Policy Name": "Users can view own addresses",

    "Command": "SELECT",

    "Using Expression": "USING: (auth.uid() = user_id)",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "user_addresses",

    "Policy Name": "Users can view their own addresses",

    "Command": "SELECT",

    "Using Expression": "USING: (user_id = auth.uid())",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "user_addresses",

    "Policy Name": "Users can update own addresses",

    "Command": "UPDATE",

    "Using Expression": "USING: (auth.uid() = user_id)",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "user_addresses",

    "Policy Name": "Users can update their own addresses",

    "Command": "UPDATE",

    "Using Expression": "USING: (user_id = auth.uid())",

    "With Check Expression": "WITH CHECK: (user_id = auth.uid())"

  },

  {

    "Table": "user_category_preferences",

    "Policy Name": "Users can delete their own category preferences",

    "Command": "DELETE",

    "Using Expression": "USING: (user_id = auth.uid())",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "user_category_preferences",

    "Policy Name": "Users can insert their own category preferences",

    "Command": "INSERT",

    "Using Expression": "No USING clause",

    "With Check Expression": "WITH CHECK: (user_id = auth.uid())"

  },

  {

    "Table": "user_category_preferences",

    "Policy Name": "Users can view their own category preferences",

    "Command": "SELECT",

    "Using Expression": "USING: (user_id = auth.uid())",

    "With Check Expression": "No WITH CHECK clause"

  },

  {

    "Table": "user_category_preferences",

    "Policy Name": "Users can update their own category preferences",

    "Command": "UPDATE",

    "Using Expression": "USING: (user_id = auth.uid())",

    "With Check Expression": "WITH CHECK: (user_id = auth.uid())"

  }

]



command 4- 

[

  {

    "Policy Table": "messages",

    "Policy Name": "Users can update their own messages",

    "Command": "UPDATE",

    "Using Expression": "(EXISTS ( SELECT 1\n   FROM conversations\n  WHERE ((conversations.id = messages.conversation_id) AND ((conversations.ngo_id = auth.uid()) OR (conversations.restaurant_id = auth.uid())))))"

  },

  {

    "Policy Table": "messages",

    "Policy Name": "Users can view messages in their conversations",

    "Command": "SELECT",

    "Using Expression": "(EXISTS ( SELECT 1\n   FROM conversations\n  WHERE ((conversations.id = messages.conversation_id) AND ((conversations.ngo_id = auth.uid()) OR (conversations.restaurant_id = auth.uid())))))"

  },

  {

    "Policy Table": "ngos",

    "Policy Name": "NGOs: public browse approved",

    "Command": "SELECT",

    "Using Expression": "(EXISTS ( SELECT 1\n   FROM profiles p\n  WHERE ((p.id = ngos.profile_id) AND (p.approval_status = 'approved'::text))))"

  },

  {

    "Policy Table": "ngos",

    "Policy Name": "Public can view approved ngos",

    "Command": "SELECT",

    "Using Expression": "(EXISTS ( SELECT 1\n   FROM profiles p\n  WHERE ((p.id = ngos.profile_id) AND (p.approval_status = 'approved'::text))))"

  },

  {

    "Policy Table": "order_items",

    "Policy Name": "NGOs can view their order items",

    "Command": "SELECT",

    "Using Expression": "(EXISTS ( SELECT 1\n   FROM orders o\n  WHERE ((o.id = order_items.order_id) AND (o.ngo_id = auth.uid()))))"

  },

  {

    "Policy Table": "order_items",

    "Policy Name": "Restaurants can view their order items",

    "Command": "SELECT",

    "Using Expression": "(order_id IN ( SELECT orders.id\n   FROM orders\n  WHERE (orders.restaurant_id = auth.uid())))"

  },

  {

    "Policy Table": "order_items",

    "Policy Name": "Users can view their order items",

    "Command": "SELECT",

    "Using Expression": "(order_id IN ( SELECT orders.id\n   FROM orders\n  WHERE (orders.user_id = auth.uid())))"

  },

  {

    "Policy Table": "order_status_history",

    "Policy Name": "Restaurants can view their order history",

    "Command": "SELECT",

    "Using Expression": "(EXISTS ( SELECT 1\n   FROM orders\n  WHERE ((orders.id = order_status_history.order_id) AND (orders.restaurant_id = auth.uid()))))"

  },

  {

    "Policy Table": "order_status_history",

    "Policy Name": "Users can view their order history",

    "Command": "SELECT",

    "Using Expression": "(EXISTS ( SELECT 1\n   FROM orders\n  WHERE ((orders.id = order_status_history.order_id) AND (orders.user_id = auth.uid()))))"

  },

  {

    "Policy Table": "payments",

    "Policy Name": "Users can view own payments",

    "Command": "SELECT",

    "Using Expression": "(EXISTS ( SELECT 1\n   FROM orders\n  WHERE ((orders.id = payments.order_id) AND (orders.user_id = auth.uid()))))"

  },

  {

    "Policy Table": "restaurants",

    "Policy Name": "Public can view approved restaurants",

    "Command": "SELECT",

    "Using Expression": "(EXISTS ( SELECT 1\n   FROM profiles p\n  WHERE ((p.id = restaurants.profile_id) AND (p.approval_status = 'approved'::text))))"

  },

  {

    "Policy Table": "restaurants",

    "Policy Name": "Restaurants: public browse approved",

    "Command": "SELECT",

    "Using Expression": "(EXISTS ( SELECT 1\n   FROM profiles p\n  WHERE ((p.id = restaurants.profile_id) AND (p.approval_status = 'approved'::text))))"

  }

command 5-

[
  {
    "Dependency Type": "ORDER_ITEMS -> ORDERS",
    "Policy Name": "Authenticated users can create order items",
    "Command": "INSERT",
    "Expression": null
  },
  {
    "Dependency Type": "ORDER_ITEMS -> ORDERS",
    "Policy Name": "NGOs can view their order items",
    "Command": "SELECT",
    "Expression": "(EXISTS ( SELECT 1\n   FROM orders o\n  WHERE ((o.id = order_items.order_id) AND (o.ngo_id = auth.uid()))))"
  },
  {
    "Dependency Type": "ORDER_ITEMS -> ORDERS",
    "Policy Name": "Restaurants can view their order items",
    "Command": "SELECT",
    "Expression": "(order_id IN ( SELECT orders.id\n   FROM orders\n  WHERE (orders.restaurant_id = auth.uid())))"
  },
  {
    "Dependency Type": "ORDER_ITEMS -> ORDERS",
    "Policy Name": "Users can insert their order items",
    "Command": "INSERT",
    "Expression": null
  },
  {
    "Dependency Type": "ORDER_ITEMS -> ORDERS",
    "Policy Name": "Users can view their order items",
    "Command": "SELECT",
    "Expression": "(order_id IN ( SELECT orders.id\n   FROM orders\n  WHERE (orders.user_id = auth.uid())))"
  },
  {
    "Dependency Type": "ORDER_STATUS_HISTORY -> ORDERS",
    "Policy Name": "Restaurants can insert status history for their orders",
    "Command": "INSERT",
    "Expression": null
  },
  {
    "Dependency Type": "ORDER_STATUS_HISTORY -> ORDERS",
    "Policy Name": "Restaurants can view their order history",
    "Command": "SELECT",
    "Expression": "(EXISTS ( SELECT 1\n   FROM orders\n  WHERE ((orders.id = order_status_history.order_id) AND (orders.restaurant_id = auth.uid()))))"
  },
  {
    "Dependency Type": "ORDER_STATUS_HISTORY -> ORDERS",
    "Policy Name": "Users can view their order history",
    "Command": "SELECT",
    "Expression": "(EXISTS ( SELECT 1\n   FROM orders\n  WHERE ((orders.id = order_status_history.order_id) AND (orders.user_id = auth.uid()))))"
  }
]

command 6-

[
  {
    "Table": "ngos",
    "Policy Count": 16,
    "SELECT Policies": 8,
    "INSERT Policies": 3,
    "UPDATE Policies": 5,
    "DELETE Policies": 0
  },
  {
    "Table": "restaurants",
    "Policy Count": 15,
    "SELECT Policies": 7,
    "INSERT Policies": 3,
    "UPDATE Policies": 5,
    "DELETE Policies": 0
  },
  {
    "Table": "user_addresses",
    "Policy Count": 8,
    "SELECT Policies": 2,
    "INSERT Policies": 2,
    "UPDATE Policies": 2,
    "DELETE Policies": 2
  },
  {
    "Table": "meals",
    "Policy Count": 7,
    "SELECT Policies": 4,
    "INSERT Policies": 1,
    "UPDATE Policies": 1,
    "DELETE Policies": 1
  },
  {
    "Table": "orders",
    "Policy Count": 7,
    "SELECT Policies": 3,
    "INSERT Policies": 2,
    "UPDATE Policies": 2,
    "DELETE Policies": 0
  },
  {
    "Table": "rush_hours",
    "Policy Count": 7,
    "SELECT Policies": 3,
    "INSERT Policies": 1,
    "UPDATE Policies": 1,
    "DELETE Policies": 1
  },
  {
    "Table": "cart_items",
    "Policy Count": 5,
    "SELECT Policies": 1,
    "INSERT Policies": 1,
    "UPDATE Policies": 1,
    "DELETE Policies": 1
  },
  {
    "Table": "order_items",
    "Policy Count": 5,
    "SELECT Policies": 3,
    "INSERT Policies": 2,
    "UPDATE Policies": 0,
    "DELETE Policies": 0
  },
  {
    "Table": "profiles",
    "Policy Count": 5,
    "SELECT Policies": 2,
    "INSERT Policies": 2,
    "UPDATE Policies": 1,
    "DELETE Policies": 0
  },
  {
    "Table": "favorites",
    "Policy Count": 4,
    "SELECT Policies": 1,
    "INSERT Policies": 1,
    "UPDATE Policies": 1,
    "DELETE Policies": 1
  },
  {
    "Table": "free_meal_notifications",
    "Policy Count": 4,
    "SELECT Policies": 2,
    "INSERT Policies": 1,
    "UPDATE Policies": 1,
    "DELETE Policies": 0
  },
  {
    "Table": "order_status_history",
    "Policy Count": 4,
    "SELECT Policies": 2,
    "INSERT Policies": 2,
    "UPDATE Policies": 0,
    "DELETE Policies": 0
  },
  {
    "Table": "user_category_preferences",
    "Policy Count": 4,
    "SELECT Policies": 1,
    "INSERT Policies": 1,
    "UPDATE Policies": 1,
    "DELETE Policies": 1
  },
  {
    "Table": "conversations",
    "Policy Count": 3,
    "SELECT Policies": 1,
    "INSERT Policies": 2,
    "UPDATE Policies": 0,
    "DELETE Policies": 0
  },
  {
    "Table": "favorite_restaurants",
    "Policy Count": 3,
    "SELECT Policies": 1,
    "INSERT Policies": 1,
    "UPDATE Policies": 0,
    "DELETE Policies": 1
  },
  {
    "Table": "meal_reports",
    "Policy Count": 3,
    "SELECT Policies": 2,
    "INSERT Policies": 1,
    "UPDATE Policies": 0,
    "DELETE Policies": 0
  },
  {
    "Table": "messages",
    "Policy Count": 3,
    "SELECT Policies": 1,
    "INSERT Policies": 1,
    "UPDATE Policies": 1,
    "DELETE Policies": 0
  },
  {
    "Table": "category_notifications",
    "Policy Count": 2,
    "SELECT Policies": 1,
    "INSERT Policies": 0,
    "UPDATE Policies": 1,
    "DELETE Policies": 0
  },
  {
    "Table": "free_meal_user_notifications",
    "Policy Count": 2,
    "SELECT Policies": 1,
    "INSERT Policies": 0,
    "UPDATE Policies": 1,
    "DELETE Policies": 0
  },
  {
    "Table": "email_queue",
    "Policy Count": 1,
    "SELECT Policies": 0,
    "INSERT Policies": 0,
    "UPDATE Policies": 0,
    "DELETE Policies": 0
  },
  {
    "Table": "payments",
    "Policy Count": 1,
    "SELECT Policies": 1,
    "INSERT Policies": 0,
    "UPDATE Policies": 0,
    "DELETE Policies": 0
  }
]

command 7-

[
  {
    "Table": "conversations",
    "Command": "INSERT",
    "Number of Policies": 2,
    "Policy Names": "Restaurants can create conversations, NGOs can create conversations"
  },
  {
    "Table": "free_meal_notifications",
    "Command": "SELECT",
    "Number of Policies": 2,
    "Policy Names": "Users can view free meal notifications, Restaurants can view their own donations"
  },
  {
    "Table": "meal_reports",
    "Command": "SELECT",
    "Number of Policies": 2,
    "Policy Names": "Users can view their own reports, Restaurants can view reports about their meals"
  },
  {
    "Table": "meals",
    "Command": "SELECT",
    "Number of Policies": 4,
    "Policy Names": "Users can view active meals, Restaurants can view their own meals, Public can view available meals, Anonymous can view active meals"
  },
  {
    "Table": "ngos",
    "Command": "INSERT",
    "Number of Policies": 3,
    "Policy Names": "NGO owners can insert own details, Service role can insert ngos, System can insert ngos"
  },
  {
    "Table": "ngos",
    "Command": "SELECT",
    "Number of Policies": 8,
    "Policy Names": "NGOs: select own, Users can view own ngo, Public can view ngos, Public can view approved ngos, Public can view NGOs, NGO owners can view own record, NGOs can view their own profile, NGOs: public browse approved"
  },
  {
    "Table": "ngos",
    "Command": "UPDATE",
    "Number of Policies": 5,
    "Policy Names": "NGOs: update own, NGO owners can update own record, NGO owners can update own details, Users can update own ngo, NGOs can update their own profile"
  },
  {
    "Table": "order_items",
    "Command": "INSERT",
    "Number of Policies": 2,
    "Policy Names": "Users can insert their order items, Authenticated users can create order items"
  },
  {
    "Table": "order_items",
    "Command": "SELECT",
    "Number of Policies": 3,
    "Policy Names": "Users can view their order items, NGOs can view their order items, Restaurants can view their order items"
  },
  {
    "Table": "order_status_history",
    "Command": "INSERT",
    "Number of Policies": 2,
    "Policy Names": "Restaurants can insert status history for their orders, Allow status history inserts"
  },
  {
    "Table": "order_status_history",
    "Command": "SELECT",
    "Number of Policies": 2,
    "Policy Names": "Restaurants can view their order history, Users can view their order history"
  },
  {
    "Table": "orders",
    "Command": "INSERT",
    "Number of Policies": 2,
    "Policy Names": "Users can create orders, Users can insert their own orders"
  },
  {
    "Table": "orders",
    "Command": "SELECT",
    "Number of Policies": 3,
    "Policy Names": "Users can view their orders, Restaurants can view their orders, NGOs can view their orders"
  },
  {
    "Table": "orders",
    "Command": "UPDATE",
    "Number of Policies": 2,
    "Policy Names": "Users can update their own orders, Restaurants can update their orders"
  },
  {
    "Table": "profiles",
    "Command": "INSERT",
    "Number of Policies": 2,
    "Policy Names": "Service role can insert profiles, Users can insert their profile"
  },
  {
    "Table": "profiles",
    "Command": "SELECT",
    "Number of Policies": 2,
    "Policy Names": "Public can view approved profiles, Users can view their profile"
  },
  {
    "Table": "restaurants",
    "Command": "INSERT",
    "Number of Policies": 3,
    "Policy Names": "System can insert restaurants, Service role can insert restaurants, Restaurant owners can insert own details"
  },
  {
    "Table": "restaurants",
    "Command": "SELECT",
    "Number of Policies": 7,
    "Policy Names": "Restaurants can view their own profile, Restaurant owners can view own record, Users can view own restaurant, Public can view restaurants, Restaurants: select own, Public can view approved restaurants, Restaurants: public browse approved"
  },
  {
    "Table": "restaurants",
    "Command": "UPDATE",
    "Number of Policies": 5,
    "Policy Names": "Users can update own restaurant, Restaurants: update own, Restaurants can update their own profile, Restaurant owners can update own record, Restaurant owners can update own details"
  },
  {
    "Table": "rush_hours",
    "Command": "SELECT",
    "Number of Policies": 3,
    "Policy Names": "Public can view active rush hours, Restaurants can view their own rush hours, Public can view rush hours"
  },
  {
    "Table": "user_addresses",
    "Command": "DELETE",
    "Number of Policies": 2,
    "Policy Names": "Users can delete own addresses, Users can delete their own addresses"
  },
  {
    "Table": "user_addresses",
    "Command": "INSERT",
    "Number of Policies": 2,
    "Policy Names": "Users can insert their own addresses, Users can insert own addresses"
  },
  {
    "Table": "user_addresses",
    "Command": "SELECT",
    "Number of Policies": 2,
    "Policy Names": "Users can view own addresses, Users can view their own addresses"
  },
  {
    "Table": "user_addresses",
    "Command": "UPDATE",
    "Number of Policies": 2,
    "Policy Names": "Users can update their own addresses, Users can update own addresses"
  }
]


command 8-
[
  {
    "Analysis Section": "=== ORDERS TABLE POLICIES ==="
  },
  {
    "Analysis Section": "NGOs can view their orders (SELECT): (ngo_id = auth.uid())"
  },
  {
    "Analysis Section": "Restaurants can update their orders (UPDATE): (restaurant_id = auth.uid())"
  },
  {
    "Analysis Section": "Restaurants can view their orders (SELECT): (restaurant_id = auth.uid())"
  },
  {
    "Analysis Section": "Users can create orders (INSERT): No USING clause"
  },
  {
    "Analysis Section": "Users can insert their own orders (INSERT): No USING clause"
  },
  {
    "Analysis Section": "Users can update their own orders (UPDATE): (user_id = auth.uid())"
  },
  {
    "Analysis Section": "Users can view their orders (SELECT): (user_id = auth.uid())"
  },
  {
    "Analysis Section": ""
  },
  {
    "Analysis Section": "=== ORDER_ITEMS TABLE POLICIES ==="
  },
  {
    "Analysis Section": "Authenticated users can create order items (INSERT): No USING clause"
  },
  {
    "Analysis Section": "NGOs can view their order items (SELECT): (EXISTS ( SELECT 1\n   FROM orders o\n  WHERE ((o.id = order_items.order_id) AND (o.ngo_id = auth.uid()))))"
  },
  {
    "Analysis Section": "Restaurants can view their order items (SELECT): (order_id IN ( SELECT orders.id\n   FROM orders\n  WHERE (orders.restaurant_id = auth.uid())))"
  },
  {
    "Analysis Section": "Users can insert their order items (INSERT): No USING clause"
  },
  {
    "Analysis Section": "Users can view their order items (SELECT): (order_id IN ( SELECT orders.id\n   FROM orders\n  WHERE (orders.user_id = auth.uid())))"
  },
  {
    "Analysis Section": ""
  },
  {
    "Analysis Section": "=== ORDER_STATUS_HISTORY TABLE POLICIES ==="
  },
  {
    "Analysis Section": "Allow status history inserts (INSERT): No USING clause"
  },
  {
    "Analysis Section": "Restaurants can insert status history for their orders (INSERT): No USING clause"
  },
  {
    "Analysis Section": "Restaurants can view their order history (SELECT): (EXISTS ( SELECT 1\n   FROM orders\n  WHERE ((orders.id = order_status_history.order_id) AND (orders.restaurant_id = auth.uid()))))"
  },
  {
    "Analysis Section": "Users can view their order history (SELECT): (EXISTS ( SELECT 1\n   FROM orders\n  WHERE ((orders.id = order_status_history.order_id) AND (orders.user_id = auth.uid()))))"
  }
]







command 10-
[
  {
    "Report": "RECURSION RISK SUMMARY",
    "Details": ""
  },
  {
    "Report": "Tables with RLS enabled",
    "Details": "21"
  },
  {
    "Report": "Total RLS policies",
    "Details": "109"
  },
  {
    "Report": "Policies with EXISTS clauses",
    "Details": "10"
  },
  {
    "Report": "Policies with subqueries (IN)",
    "Details": "2"
  },
  {
    "Report": "Order-related circular dependencies",
    "Details": "5"
  }
] 
