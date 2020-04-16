import { column } from "../utils/template";
import data from "../data";
import Card from "./Card";
import CardCreator from "./CardCreator";

export default class Column {
	$column = null;
	$columnHeader = null;
	$columnBody = null;
	$cardContainer = null;
	$counter = null;
	cardCreatorIsShowing = false;

	constructor({ $target, initialData }) {
		this.$target = $target;
		this.initialData = initialData;
		this.columnIndex = initialData.index;

		this.render();
		this.cacheDomElements();
		this.bindeEventListener();

		this.renderCards();

		this.cardCreator = new CardCreator({
			$target: this,
			data: {
				visible: false,
			},
		});
	}

	render() {
		const { columnName, cards } = this.initialData;
		this.$target.insertAdjacentHTML("beforeend", column(columnName, cards.length));
	}

	cacheDomElements() {
		this.$column = [...this.$target.children][this.columnIndex];
		this.$columnHeader = this.$column.querySelector(".column__header");
		this.$columnBody = this.$column.querySelector(".column__body");
		this.$cardContainer = this.$column.querySelector(".card-container");
		this.$counter = this.$columnHeader.querySelector(".column__counter");
	}

	bindeEventListener() {
		const addCardButton = this.$columnHeader.querySelector(".add-card");
		addCardButton.addEventListener("click", this.handleCardCreator.bind(this));
	}

	renderCards() {
		const {
			initialData: { cards },
		} = this;
		if (cards.length !== 0) {
			cards.forEach((card) => new Card({ $target: this, data: card }));
		}
	}

	handleCardCreator() {
		if (!this.cardCreatorIsShowing) {
			this.cardCreator.toggleDisplay({ visible: true });
			this.cardCreatorIsShowing = true;
		} else {
			this.cardCreator.toggleDisplay({ visible: false });
			this.cardCreatorIsShowing = false;
		}
	}

	createCardObj(value, cardList) {
		return {
			userId: "reese",
			title: "제목없음",
			contents: value,
			device: "web",
			row: cardList.length + 1,
		};
	}

	addCard(value) {
		// update data
		const cardList = data.columns.find((column) => column.index === this.columnIndex).cards;
		const newCardObj = this.createCardObj.call(this, value, cardList);
		cardList.push(newCardObj);

		// send newCardObj to the server
		// synchronize card id with the one received from the server

		// render Card DOM
		new Card({ $target: this, data: newCardObj });

		// update counter
		this.$counter.textContent = Number(this.$counter.textContent) + 1;
		console.log("card added!", data);
	}

	deleteCard({ $card, id }) {
		// update data
		const cardList = data.columns.find((column) => column.index === this.columnIndex).cards;
		data.columns.find((column) => column.index === this.columnIndex).cards = cardList.filter(
			(card) => card.id !== id
		);

		// send card id to the server

		// remove Card DOM
		this.$cardContainer.removeChild($card);

		// update counter
		this.$counter.textContent = Number(this.$counter.textContent) - 1;
		console.log("card deleted!", data);
	}

	updateCard({ $card, id, contents }) {
		// update data
		const cardList = data.columns.find((column) => column.index === this.columnIndex).cards;
		let updatedCard;
		for (let index = 0, length = cardList.length; index < length; index++) {
			if (cardList[index].id === id) {
				cardList[index].contents = contents;
				updatedCard = cardList[index];
				break;
			}
		}

		// send updatedCard to the server

		// render new contents in the card
		$card.querySelector(".contents").textContent = contents;
		console.log("card updated!", data);
	}
}