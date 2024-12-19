#!/bin/bash

# Inventory File
INVENTORY_FILE="inventory.csv"

# Ensure the inventory file exists
if [ ! -f "$INVENTORY_FILE" ]; then
    echo "ID,Name,Price,Quantity" > "$INVENTORY_FILE"
fi

# Function to display the inventory list using Zenity
show_inventory() {
    INVENTORY=$(cat "$INVENTORY_FILE")
    zenity --info --title="Inventory List" --text="$INVENTORY"
}

# Function to add a new product
add_product() {
    # Get product details via Zenity input boxes
    product_details=$(zenity --forms --title="Add Product" \
        --text="Enter product details" \
        --add-entry="Product ID" \
        --add-entry="Product Name" \
        --add-entry="Price" \
        --add-entry="Quantity")

    if [ $? -eq 0 ]; then
        # Split the input into individual variables
        IFS="|" read -r product_id product_name price quantity <<< "$product_details"
        
        # Validate that price and quantity are numbers
        if [[ ! "$price" =~ ^[0-9]+(\.[0-9]+)?$ ]] || [[ ! "$quantity" =~ ^[0-9]+$ ]]; then
            zenity --error --text="Price and quantity must be valid numbers!"
            return
        fi
        
        # Append the new product to the inventory file
        echo "$product_id,$product_name,$price,$quantity" >> "$INVENTORY_FILE"
        zenity --info --text="Product added successfully!"
    fi
}

# Function to update a product
update_product() {
    # List existing products for the user to choose from
    product_id=$(zenity --list --title="Select Product" \
        --column="Product ID" --column="Name" \
        $(awk -F, 'NR > 1 {print $1 " " $2}' "$INVENTORY_FILE") --separator=" ")

    if [ $? -eq 0 ]; then
        # Get the new details via Zenity
        updated_details=$(zenity --forms --title="Update Product" \
            --text="Update the details of product ID $product_id" \
            --add-entry="New Product Name" \
            --add-entry="New Price" \
            --add-entry="New Quantity")

        if [ $? -eq 0 ]; then
            IFS="|" read -r new_name new_price new_quantity <<< "$updated_details"
            
            # Validate the price and quantity
            if [[ ! "$new_price" =~ ^[0-9]+(\.[0-9]+)?$ ]] || [[ ! "$new_quantity" =~ ^[0-9]+$ ]]; then
                zenity --error --text="Price and quantity must be valid numbers!"
                return
            fi

            # Update the product in the inventory file
            awk -F, -v id="$product_id" -v name="$new_name" -v price="$new_price" -v qty="$new_quantity" 'BEGIN{OFS=","} 
                {if ($1 == id) {$2=name; $3=price; $4=qty} print}' "$INVENTORY_FILE" > temp.csv && mv temp.csv "$INVENTORY_FILE"
            
            zenity --info --text="Product updated successfully!"
        fi
    fi
}

# Function to delete a product
delete_product() {
    # List existing products for the user to choose from
    product_id=$(zenity --list --title="Delete Product" \
        --column="Product ID" --column="Name" \
        $(awk -F, 'NR > 1 {print $1 " " $2}' "$INVENTORY_FILE") --separator=" ")

    if [ $? -eq 0 ]; then
        # Delete the selected product from the inventory
        awk -F, -v id="$product_id" 'BEGIN{OFS=","} {if ($1 != id) print}' "$INVENTORY_FILE" > temp.csv && mv temp.csv "$INVENTORY_FILE"
        zenity --info --text="Product deleted successfully!"
    fi
}

# Function to generate the inventory report
generate_report() {
    report=$(cat "$INVENTORY_FILE")
    zenity --info --title="Inventory Report" --text="$report"
}

# Main Menu
while true; do
    ACTION=$(zenity --list --title="Inventory Management System" \
        --column="Action" \
        "Add Product" \
        "View Inventory" \
        "Update Product" \
        "Delete Product" \
        "Generate Report" \
        "Exit")

    case $ACTION in
        "Add Product")
            add_product
            ;;
        "View Inventory")
            show_inventory
            ;;
        "Update Product")
            update_product
            ;;
        "Delete Product")
            delete_product
            ;;
        "Generate Report")
            generate_report
            ;;
        "Exit")
            break
            ;;
        *)
            zenity --error --text="Invalid choice, please try again."
            ;;
    esac
done
