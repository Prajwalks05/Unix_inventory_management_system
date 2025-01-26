#!/bin/bash

FILE="inventory.txt"

# Function to display the inventory
display_inventory() {
    if [ ! -s "$FILE" ]; then
        zenity --info --title="Inventory" --text="No data available in the inventory!"
        return
    fi
    
    inventory=$(awk -F "|" '{printf "Name: %s\nPrice: %s\nQuantity: %s\nExpiry Days: %s\nInventory Date: %s\nExpiry Date: %s\nCategory: %s\n\n", $1, $2, $3, $4, $5, $6, $7}' $FILE)
    zenity --text-info --title="Inventory Data" --filename=<(echo "$inventory") --width=600 --height=400
}

# Function to add a new product
add_product() {
    categories=("Dairy" "Bakery" "Grocery" "Fruits" "Meat")
    category=$(zenity --list --title="Select Category" --column="Category" "${categories[@]}")
    [ $? -ne 0 ] && return

    name=$(zenity --entry --title="Add Product" --text="Enter Product Name")
    [ $? -ne 0 ] && return
    
    price=$(zenity --entry --title="Add Product" --text="Enter Product Price")
    [ $? -ne 0 ] && return
    
    quantity=$(zenity --entry --title="Add Product" --text="Enter Product Quantity")
    [ $? -ne 0 ] && return
    
    expiry_days=$(zenity --entry --title="Add Product" --text="Enter Expiry Days")
    [ $? -ne 0 ] && return

    if [ -z "$name" ] || [ -z "$price" ] || [ -z "$quantity" ] || [ -z "$expiry_days" ]; then
        zenity --error --title="Error" --text="Please fill all fields to add the product."
        return
    fi

    if ! [[ "$expiry_days" =~ ^[0-9]+$ ]]; then
        zenity --error --title="Error" --text="Expiry Days must be a valid number."
        return
    fi

    inventory_date=$(zenity --calendar --title="Select Inventory Date" --text="Choose inventory date")
    [ $? -ne 0 ] && return

    inventory_date=$(date -I -d "$inventory_date" 2>/dev/null)
    if [ $? -ne 0 ]; then
        zenity --error --title="Error" --text="Invalid inventory date format. Please select a valid date."
        return
    fi

    expiry_date=$(date -I -d "$inventory_date + $expiry_days days")
    echo "$name|$price|$quantity|$expiry_days|$inventory_date|$expiry_date|$category" >> $FILE
    zenity --info --title="Success" --text="Product added successfully!"
}

# Function to update product
update_product() {
    if [ ! -s "$FILE" ]; then
        zenity --error --title="Error" --text="No products available to update!"
        return
    fi

    products=$(awk -F "|" '{print $1}' $FILE)
    product_name=$(zenity --list --title="Update Product" --column="Products" $products)
    [ $? -ne 0 ] && return

    current_line=$(grep "^$product_name|" $FILE)
    current_price=$(echo $current_line | cut -d '|' -f 2)
    current_quantity=$(echo $current_line | cut -d '|' -f 3)
    current_expiry_days=$(echo $current_line | cut -d '|' -f 4)
    current_inventory_date=$(echo $current_line | cut -d '|' -f 5)
    current_expiry_date=$(echo $current_line | cut -d '|' -f 6)
    current_category=$(echo $current_line | cut -d '|' -f 7)

    details=$(zenity --forms --title="Update Product" \
        --text="Update product details" \
        --add-entry="New Price (current: $current_price)" \
        --add-entry="New Quantity (current: $current_quantity)")
    [ $? -ne 0 ] && return

    price=$(echo "$details" | cut -d '|' -f 1)
    quantity=$(echo "$details" | cut -d '|' -f 2)

    new_line="$product_name|$price|$quantity|$current_expiry_days|$current_inventory_date|$current_expiry_date|$current_category"
    sed -i "/^$product_name|/c\\$new_line" $FILE
    zenity --info --title="Success" --text="Product updated successfully!"
}

# Function to delete a product
delete_product() {
    if [ ! -s "$FILE" ]; then
        zenity --error --title="Error" --text="No products available to delete!"
        return
    fi

    products=$(awk -F "|" '{print $1}' $FILE)
    product_name=$(zenity --list --title="Delete Product" --column="Products" $products)
    [ $? -ne 0 ] && return

    sed -i "/^$product_name|/d" $FILE
    zenity --info --title="Success" --text="Product deleted successfully!"
}

# Function to search for a product
search_product() {
    if [ ! -s "$FILE" ]; then
        zenity --error --title="Error" --text="No products available to search!"
        return
    fi

    search_term=$(zenity --entry --title="Search Product" --text="Enter product name or category to search:")
    [ $? -ne 0 ] && return

    results=$(grep -i "$search_term" "$FILE")
    if [ -z "$results" ]; then
        zenity --info --title="Search Results" --text="No matching products found."
    else
        formatted_results=$(echo "$results" | awk -F "|" '{printf "Name: %s\nPrice: %s\nQuantity: %s\nExpiry Days: %s\nInventory Date: %s\nExpiry Date: %s\nCategory: %s\n\n", $1, $2, $3, $4, $5, $6, $7}')
        zenity --text-info --title="Search Results" --filename=<(echo "$formatted_results") --width=600 --height=400
    fi
}

# Main script logic
while true; do
    choice=$(zenity --list --title="Inventory Management" --column="Option" --hide-header \
        "Display Inventory" "Add Product" "Update Product (Price and Quantity)" "Delete Product" "Search Product" "Exit")
    
    case $choice in
        "Display Inventory") display_inventory ;;
        "Add Product") add_product ;;
        "Update Product (Price and Quantity)") update_product ;;
        "Delete Product") delete_product ;;
        "Search Product") search_product ;;
        "Exit") exit ;;
        *) zenity --error --title="Error" --text="Invalid choice!";;
    esac
done
