# Ethernaut Challenge Solutions

This repository contains solutions for the [Ethernaut](https://ethernaut.openzeppelin.com/) wargame, a platform for learning about Ethereum and smart contract security. The solutions are written using [Hardhat](https://hardhat.org/), [Ethers.js](https://ethers.io/), and [TypeScript](https://www.typescriptlang.org/).

## Project Structure

The repository is organized by level. Each level has its own directory containing:

- `contracts/`: The original Solidity contract from the Ethernaut challenge, and any necessary wrapper or attack contracts.
- `scripts/exploit.ts`: The TypeScript script that executes the exploit.
- `solution.md`: A detailed write-up explaining the vulnerability and the steps taken in the exploit script.
- `level.md`: The original level description from Ethernaut.

## Setup and Installation

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/<your-username>/ethernaut-solutions.git
    cd ethernaut-solutions
    ```

2.  **Install dependencies:**
    This project uses `npm` for package management.

    ```bash
    npm install
    ```

3.  **Set up environment variables:**
    Create a `.env` file by copying the example file.

    ```bash
    cp .env.example .env
    ```

    Then, edit the `.env` file and fill in your environment-specific variables, such as your Sepolia RPC URL and private key.

    ```dotenv
    # .env
    SEPOLIA_RPC_URL="<your_sepolia_rpc_url>"
    PRIVATE_KEY="<your_wallet_private_key>"
    ```

## How to Run Solutions

To run the exploit for a specific level, use the `exploit` script defined in `package.json`. You need to provide the level number as an argument.

**Usage:**

```bash
npm run exploit -- <level_number>
```

**Examples:**

- To run the solution for level 1 (Fallback):
  ```bash
  npm run exploit -- 1
  ```
- To run the solution for level 5 (Token):
  ```bash
  npm run exploit -- 5
  ```

The script will automatically find the correct directory and execute the corresponding `exploit.ts` file.
