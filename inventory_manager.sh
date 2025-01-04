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
    # Static categories
    categories=("Dairy" "Bakery" "Grocery" "Fruits" "Meat")

    # Ask the user to select a category from predefined categories
    category=$(zenity --list --title="Select Category" --column="Category" "${categories[@]}")
    [ $? -ne 0 ] && return  # If user clicks Cancel

    # Get product details using zenity --entry dialogs
    name=$(zenity --entry --title="Add Product" --text="Enter Product Name")
    [ $? -ne 0 ] && return  # If user clicks Cancel
    
    price=$(zenity --entry --title="Add Product" --text="Enter Product Price")
    [ $? -ne 0 ] && return  # If user clicks Cancel
    
    quantity=$(zenity --entry --title="Add Product" --text="Enter Product Quantity")
    [ $? -ne 0 ] && return  # If user clicks Cancel
    
    expiry_days=$(zenity --entry --title="Add Product" --text="Enter Expiry Days")
    [ $? -ne 0 ] && return  # If user clicks Cancel

    # Validate that fields are not empty
    if [ -z "$name" ] || [ -z "$price" ] || [ -z "$quantity" ] || [ -z "$expiry_days" ]; then
        zenity --error --title="Error" --text="Please fill all fields to add the product."
        return
    fi

    # Check if expiry_days is a valid number
    if ! [[ "$expiry_days" =~ ^[0-9]+$ ]]; then
        zenity --error --title="Error" --text="Expiry Days must be a valid number."
        return
    fi

    # Ask for the Inventory Date using calendar dialog
    inventory_date=$(zenity --calendar --title="Select Inventory Date" --text="Choose inventory date")
    [ $? -ne 0 ] && return  # If user clicks Cancel
    
    # Validate the inventory date format and ensure it's a valid date
    inventory_date=$(date -I -d "$inventory_date" 2>/dev/null)
    if [ $? -ne 0 ]; then
        zenity --error --title="Error" --text="Invalid inventory date format. Please select a valid date."
        return
    fi

    # Calculate expiry date by adding expiry days to the inventory date
    expiry_date=$(date -I -d "$inventory_date + $expiry_days days")
    
    # Append the new product to the file with proper format
    echo "$name|$price|$quantity|$expiry_days|$inventory_date|$expiry_date|$category" >> $FILE
    
    # Notify user of success
    zenity --info --title="Success" --text="Product added successfully!"
}

# Function to update price and quantity only
update_product() {
    if [ ! -s "$FILE" ]; then
        zenity --error --title="Error" --text="No products available to update!"
        return
    fi

    # Create a list of product names
    products=$(awk -F "|" '{print $1}' $FILE)
    product_name=$(zenity --list --title="Update Product" --column="Products" $products)
    [ $? -ne 0 ] && return

    # Check if product exists
    current_line=$(grep "^$product_name|" $FILE)
    current_price=$(echo $current_line | cut -d '|' -f 2)
    current_quantity=$(echo $current_line | cut -d '|' -f 3)
    current_expiry_days=$(echo $current_line | cut -d '|' -f 4)
    current_inventory_date=$(echo $current_line | cut -d '|' -f 5)
    current_expiry_date=$(echo $current_line | cut -d '|' -f 6)
    current_category=$(echo $current_line | cut -d '|' -f 7)
    
    # Get new details
    details=$(zenity --forms --title="Update Product" \
        --text="Update product details" \
        --add-entry="New Price (current: $current_price)" \
        --add-entry="New Quantity (current: $current_quantity)")
    [ $? -ne 0 ] && return
    
    price=$(echo "$details" | cut -d '|' -f 1)
    quantity=$(echo "$details" | cut -d '|' -f 2)
    
    # Update the line
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

    # Create a list of product names
    products=$(awk -F "|" '{print $1}' $FILE)
    product_name=$(zenity --list --title="Delete Product" --column="Products" $products)
    [ $? -ne 0 ] && return

    # Remove product
    sed -i "/^$product_name|/d" $FILE
    zenity --info --title="Success" --text="Product deleted successfully!"
}

# Main script logic
while true; do
    choice=$(zenity --list --title="Inventory Management" --column="Option" --hide-header \
        "Display Inventory" "Add Product" "Update Product (Price and Quantity)" "Delete Product" "Exit")
    
    case $choice in
        "Display Inventory") display_inventory ;;
        "Add Product") add_product ;;
        "Update Product (Price and Quantity)") update_product ;;
        "Delete Product") delete_product ;;
        "Exit") exit ;;
        *) zenity --error --title="Error" --text="Invalid choice!";;
    esac
done
